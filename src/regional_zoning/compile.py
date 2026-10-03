"""Compile the regional zoning district layer.

Builds `zoning_inventory.zoning_compiled` from the baseline Regrid zoning
layer (`inventory.SOURCE_TABLE`), following docs/project-workplan.md:

- **Schema:** Regrid's zoning columns, same names, types, and order, followed
  by the project fields (`layer_role`, `base_zoning`, `code_status`,
  `standards_source`, `local_source_id`, `clipped`, `compiled_on`, `qa_status`).
- **Overlays:** combined Regrid codes (e.g. Berkeley `R-1H`) are split using
  `inventory/overlay_codes.csv`: `base_zoning` holds the base district, and
  overlay districts go to `zoning_overlays` (one row per `overlay_id`, with
  geometry) linked to districts in `zoning_overlay_links` (`zoning_id`,
  `overlay_id`). `base_zoning` is NULL where a polygon carries only an overlay.
- **Geometry:** Regrid districts, clipped to each jurisdiction's official
  boundary (`zoning_inventory.jurisdiction_boundaries`); slivers under
  0.05 acre are dropped. Streets and water stay unzoned.
- **Standards:** researched values from `inventory/standards_research.csv`
  are written into Regrid's own numeric fields:
  a number replaces the field; `not_regulated` becomes -9999 ("not
  applicable"); a rule with no single number (e.g. "per General Plan")
  becomes -5555 ("refer to the zoning code").

Also writes `zoning_inventory.compile_log` (one row per jurisdiction) and
`zoning_inventory.compile_review` (clipped-off pieces of 10+ acres that lie
inside another jurisdiction).

Usage:
    python -m regional_zoning.compile            # drafted + approved research
    python -m regional_zoning.compile --approved-only
"""

import sys
from datetime import date

import pandas as pd
from sqlalchemy import text

from regional_zoning.db import get_engine
from regional_zoning.inventory import (
    DB_SCHEMA, INVENTORY_DIR, NOT_APPLICABLE, PRIORITY_FIELDS, REFER_TO_CODE, SOURCE_TABLE,
)

COMPILED = f"{DB_SCHEMA}.zoning_compiled"
BOUNDARIES = f"{DB_SCHEMA}.jurisdiction_boundaries"
AREA_SRID = 3310  # California Albers
SQ_M_PER_ACRE = 4046.8564
SLIVER_ACRES = 0.05
REVIEW_ACRES = 10
SNAP_M = 0.01

PROJECT_FIELDS = {
    "layer_role": "text",
    "base_zoning": "text",
    "code_status": "text",
    "standards_source": "text",
    "local_source_id": "integer",
    "clipped": "boolean",
    "compiled_on": "date",
    "qa_status": "text",
}


def _regrid_columns(conn) -> list[str]:
    schema, table = SOURCE_TABLE.split(".")
    return conn.execute(text(
        "select column_name from information_schema.columns "
        "where table_schema = :s and table_name = :t order by ordinal_position"
    ), {"s": schema, "t": table}).scalars().all()


def standards_overrides(statuses: tuple[str, ...]) -> pd.DataFrame:
    """Researched values to write into Regrid's fields, one row per code + field."""
    r = pd.read_csv(INVENTORY_DIR / "standards_research.csv", dtype=str, keep_default_na=False)
    r = r[r.status.isin(statuses) & r.field.isin(PRIORITY_FIELDS)].copy()

    def compiled_value(row) -> float:
        if row.value_type == "not_regulated":
            return NOT_APPLICABLE
        if row.value.strip():
            return float(row.value)
        return REFER_TO_CODE

    r["value_num"] = r.apply(compiled_value, axis=1)
    return r[["municipality_id", "zoning", "field", "value_num", "status"]]


def _load_inputs(conn, statuses: tuple[str, ...]) -> None:
    """Small lookup tables the compile query joins to (replaced each run)."""
    engine = conn.engine
    s = standards_overrides(statuses)
    wide = s.pivot_table(index=["municipality_id", "zoning"], columns="field",
                         values="value_num", aggfunc="first")
    wide = wide.reindex(columns=PRIORITY_FIELDS)
    wide.columns = [f"r_{c}" for c in wide.columns]
    # 'approved' only if every applied value for the code is approved
    wide["r_status"] = s.groupby(["municipality_id", "zoning"]).status.agg(
        lambda x: "approved" if (x == "approved").all() else "drafted")
    wide = wide.reset_index()
    wide["municipality_id"] = wide.municipality_id.astype(int)
    wide.to_sql("_compile_standards", engine, schema=DB_SCHEMA, if_exists="replace", index=False)

    codes = pd.read_csv(INVENTORY_DIR / "zoning_codes.csv", dtype={"zoning": str},
                        keep_default_na=False)[["municipality_id", "zoning", "layer_role", "code_status"]]
    codes.to_sql("_compile_codes", engine, schema=DB_SCHEMA, if_exists="replace", index=False)

    oc = pd.read_csv(INVENTORY_DIR / "overlay_codes.csv", dtype={"zoning": str, "base_zoning": str},
                     keep_default_na=False)[["municipality_id", "zoning", "base_zoning", "overlay_codes"]]
    oc.to_sql("_compile_overlay_codes", engine, schema=DB_SCHEMA, if_exists="replace", index=False)
    od = pd.read_csv(INVENTORY_DIR / "overlay_definitions.csv", keep_default_na=False)
    od.to_sql("_compile_overlay_defs", engine, schema=DB_SCHEMA, if_exists="replace", index=False)

    src = INVENTORY_DIR / "zoning_sources.csv"
    reg = pd.read_csv(src, keep_default_na=False) if src.exists() else pd.DataFrame(
        columns=["municipality_id", "status"])
    reg[reg.status == "active"][["municipality_id"]].drop_duplicates().to_sql(
        "_compile_sources", engine, schema=DB_SCHEMA, if_exists="replace", index=False)


def compile_layer(statuses: tuple[str, ...] = ("drafted", "approved")) -> pd.DataFrame:
    engine = get_engine()
    with engine.begin() as conn:
        _load_inputs(conn, statuses)
        regrid_cols = _regrid_columns(conn)

        select_cols = []
        for c in regrid_cols:
            if c == "geometry":
                select_cols.append("st_multi(st_transform(c.gc, 4326))::geometry(MultiPolygon, 4326) as geometry")
            elif c in PRIORITY_FIELDS:
                select_cols.append(f"coalesce(s.r_{c}, c.{c}) as {c}")
            else:
                select_cols.append(f"c.{c}")
        replaced = " or ".join(f"s.r_{f} is not null" for f in PRIORITY_FIELDS)
        project = f"""
            coalesce(k.layer_role, 'base') as layer_role,
            case when oc.zoning is null then c.zoning else nullif(oc.base_zoning, '') end as base_zoning,
            coalesce(k.code_status, 'current') as code_status,
            case when {replaced} then 'research (' || s.r_status || ')' else 'regrid' end as standards_source,
            src.municipality_id as local_source_id,
            c.clipped,
            current_date as compiled_on,
            'pending'::text as qa_status"""

        # Boundaries projected once; a subdivided, indexed copy for fast overlap tests
        conn.execute(text(f"""
            create temp table _bnd on commit drop as
            select municipality_id, jurisdiction, st_transform(geometry, {AREA_SRID}) g from {BOUNDARIES}"""))
        conn.execute(text("create index on _bnd (municipality_id)"))
        conn.execute(text("""
            create temp table _bnd_sub on commit drop as
            select municipality_id, jurisdiction, st_subdivide(g, 256) g from _bnd"""))
        conn.execute(text("create index on _bnd_sub using gist (g)"))

        conn.execute(text(f"drop table if exists {COMPILED}"))
        conn.execute(text(f"""
            create table {COMPILED} as
            with b as (select municipality_id, g from _bnd),
            z as (
                select z.*, st_snaptogrid(st_transform(st_makevalid(z.geometry), {AREA_SRID}), {SNAP_M}) g3
                from {SOURCE_TABLE} z),
            c as (
                select z.*, b.g bg,
                       not st_coveredby(z.g3, b.g) as clipped,
                       case when st_coveredby(z.g3, b.g) then z.g3
                            else st_collectionextract(st_makevalid(st_intersection(z.g3, b.g)), 3)
                       end as gc
                from z join b using (municipality_id))
            select {", ".join(select_cols)}, {project}
            from c
            left join {DB_SCHEMA}._compile_standards s using (municipality_id, zoning)
            left join {DB_SCHEMA}._compile_codes k using (municipality_id, zoning)
            left join {DB_SCHEMA}._compile_sources src using (municipality_id)
            left join {DB_SCHEMA}._compile_overlay_codes oc using (municipality_id, zoning)
            where not st_isempty(c.gc) and st_area(c.gc) >= {SLIVER_ACRES * SQ_M_PER_ACRE}
        """))
        conn.execute(text(f"alter table {COMPILED} add primary key (zoning_id)"))
        conn.execute(text(f"create index zoning_compiled_gix on {COMPILED} using gist (geometry)"))
        conn.execute(text(f"create index zoning_compiled_muni on {COMPILED} (municipality_id, zoning)"))

        # Overlay districts and their links to base districts
        conn.execute(text(f"drop table if exists {DB_SCHEMA}.zoning_overlay_links"))
        conn.execute(text(f"""
            create table {DB_SCHEMA}.zoning_overlay_links as
            select distinct z.zoning_id, d.overlay_id::integer as overlay_id, 'zone_code'::text as relation
            from {COMPILED} z
            join {DB_SCHEMA}._compile_overlay_codes oc using (municipality_id, zoning)
            cross join lateral unnest(string_to_array(nullif(oc.overlay_codes, ''), ';')) as t(overlay_code)
            join {DB_SCHEMA}._compile_overlay_defs d
              on d.municipality_id = z.municipality_id and d.overlay_code = t.overlay_code"""))
        conn.execute(text(f"alter table {DB_SCHEMA}.zoning_overlay_links add primary key (zoning_id, overlay_id)"))
        conn.execute(text(f"drop table if exists {DB_SCHEMA}.zoning_overlays"))
        conn.execute(text(f"""
            create table {DB_SCHEMA}.zoning_overlays as
            select d.overlay_id::integer as overlay_id, d.municipality_id::integer as municipality_id,
                   d.jurisdiction, d.overlay_code, nullif(d.overlay_name, '') as overlay_name,
                   nullif(d.overlay_type, '') as overlay_type, 'regrid_zone_code'::text as source,
                   count(z.zoning_id) as districts,
                   round((sum(st_area(st_transform(z.geometry, {AREA_SRID}))) / {SQ_M_PER_ACRE})::numeric, 1) as acres,
                   st_multi(st_union(z.geometry))::geometry(MultiPolygon, 4326) as geometry
            from {DB_SCHEMA}._compile_overlay_defs d
            join {DB_SCHEMA}.zoning_overlay_links l on l.overlay_id = d.overlay_id::integer
            join {COMPILED} z on z.zoning_id = l.zoning_id
            group by 1, 2, 3, 4, 5, 6"""))
        conn.execute(text(f"alter table {DB_SCHEMA}.zoning_overlays add primary key (overlay_id)"))
        conn.execute(text(f"create index zoning_overlays_gix on {DB_SCHEMA}.zoning_overlays using gist (geometry)"))

        # Clipped-off zoning that lies inside another jurisdiction, for review
        conn.execute(text(f"""
            create temp table _removed on commit drop as
            select z.zoning_id, z.municipality_id, z.zoning,
                   st_difference(st_snaptogrid(st_transform(st_makevalid(z.geometry), {AREA_SRID}), {SNAP_M}), b.g) g
            from {SOURCE_TABLE} z join _bnd b using (municipality_id)
            where z.zoning_id in (select zoning_id from {COMPILED} where clipped)
               or z.zoning_id not in (select zoning_id from {COMPILED})"""))
        conn.execute(text("create index on _removed using gist (g)"))
        conn.execute(text(f"drop table if exists {DB_SCHEMA}.compile_review"))
        conn.execute(text(f"""
            create table {DB_SCHEMA}.compile_review as
            select r.zoning_id, r.municipality_id, r.zoning,
                   o.municipality_id as other_municipality_id, o.jurisdiction as other_jurisdiction,
                   round((sum(st_area(st_intersection(r.g, o.g))) / {SQ_M_PER_ACRE})::numeric, 1) as acres
            from _removed r join _bnd_sub o on o.municipality_id <> r.municipality_id and st_intersects(r.g, o.g)
            group by 1, 2, 3, 4, 5
            having sum(st_area(st_intersection(r.g, o.g))) >= {REVIEW_ACRES * SQ_M_PER_ACRE}
        """))

        log = pd.read_sql(text(f"""
            with src as (
                select municipality_id, count(*) polygons_in,
                       sum(st_area(st_transform(st_makevalid(geometry), {AREA_SRID}))) area_in
                from {SOURCE_TABLE} group by 1),
            out as (
                select municipality_id, count(*) polygons_out, count(*) filter (where clipped) clipped,
                       sum(st_area(st_transform(geometry, {AREA_SRID}))) area_out,
                       count(*) filter (where standards_source <> 'regrid') polygons_with_research
                from {COMPILED} group by 1),
            rev as (select municipality_id, count(*) review_pieces, sum(acres) review_acres
                    from {DB_SCHEMA}.compile_review group by 1)
            select b.municipality_id, b.jurisdiction,
                   coalesce(src.polygons_in, 0) polygons_in, coalesce(out.polygons_out, 0) polygons_out,
                   coalesce(out.clipped, 0) polygons_clipped,
                   round((coalesce(src.area_in, 0) / {SQ_M_PER_ACRE})::numeric) acres_in,
                   round((coalesce(out.area_out, 0) / {SQ_M_PER_ACRE})::numeric) acres_out,
                   round(((coalesce(src.area_in, 0) - coalesce(out.area_out, 0)) / {SQ_M_PER_ACRE})::numeric) acres_removed,
                   coalesce(rev.review_pieces, 0) review_pieces, coalesce(rev.review_acres, 0) review_acres,
                   coalesce(out.polygons_with_research, 0) polygons_with_research,
                   current_date compiled_on
            from {BOUNDARIES} b
            left join src using (municipality_id) left join out using (municipality_id)
            left join rev using (municipality_id)
            order by b.jurisdiction
        """), conn)
        log.to_sql("compile_log", conn, schema=DB_SCHEMA, if_exists="replace", index=False)
        for t in ("_compile_standards", "_compile_codes", "_compile_sources",
                  "_compile_overlay_codes", "_compile_overlay_defs"):
            conn.execute(text(f"drop table {DB_SCHEMA}.{t}"))
    return log


def main() -> None:
    statuses = ("approved",) if "--approved-only" in sys.argv else ("drafted", "approved")
    log = compile_layer(statuses)
    print(f"{COMPILED}: {log.polygons_out.sum():,} polygons from {log.polygons_in.sum():,} "
          f"({log.polygons_clipped.sum():,} clipped); research applied: {statuses}")
    print(f"acres in {log.acres_in.sum():,.0f} -> out {log.acres_out.sum():,.0f} "
          f"(removed {log.acres_removed.sum():,.0f}); review pieces: {log.review_pieces.sum()} "
          f"({log.review_acres.sum():,.0f} ac)")
    print(f"compiled on {date.today()}")


if __name__ == "__main__":
    main()
