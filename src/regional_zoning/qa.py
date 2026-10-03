"""Automated QA/QC checks on the compiled zoning layer.

Runs the checks in docs/project-workplan.md ("QA/QC step") for every
jurisdiction and writes:

- `zoning_inventory.qa_report` and `inventory/qa_report.csv`: one row per
  jurisdiction with each metric, the flags raised, and `qa_status`
  (`fail` if any error, `warn` if only warnings, otherwise `pass`).
- `zoning_compiled.qa_status`: the jurisdiction's status, on every polygon.

Automated QA does not approve anything. Human review and jurisdiction
sign-off follow (see the work plan).

Usage:
    python -m regional_zoning.qa
"""

import time

import pandas as pd
from sqlalchemy import text

from regional_zoning.compile import AREA_SRID, BOUNDARIES, COMPILED, SQ_M_PER_ACRE
from regional_zoning.db import get_engine
from regional_zoning.inventory import DB_SCHEMA, INVENTORY_DIR, PRIORITY_FIELDS, SOURCE_TABLE

# Later extract used to detect "baseline older than code"
COMPARATOR_TABLE = "regrid_raw_202606.zoning_union"
PARCELS_TABLE = SOURCE_TABLE.replace("zoning_union", "parcels_union")

OVERLAP_ERROR_ACRES = 0.1
SPILL_REVIEW_ACRES = 10
UNZONED_WARN_PCT = 30
LOCAL_COVERAGE_MIN_PCT = 95
UNMATCHED_PARCELS_WARN_PCT = 1
GAP_MIN_ACRES = 0.5  # unzoned pieces smaller than this are boundary noise
# Street/water networks catch a few right-of-way parcels; real gaps hold many
GAP_PARCELS_MIN = 25
GAP_PARCELS_PCT = 1

# Plausible ranges for real (>= 0) values; placeholders are negative
RANGES = {
    "max_building_height_ft": (10, 1200),  # San Francisco downtown districts reach 1,000 ft
    "max_far": (0, 30),
    "max_density_du_per_acre": (0, 500),
    "min_lot_area_sq_ft": (0, 100_000_000),
}
MULTIFAMILY_SUBTYPES = ("Multi Family", "Two Family", "Mixed Use")

# Flag name -> (severity, description)
FLAGS = {
    "invalid_geometry": ("error", "invalid geometries in compiled layer"),
    "base_self_overlap": ("error", f"base districts overlap each other (>= {OVERLAP_ERROR_ACRES} ac)"),
    "cross_jurisdiction_overlap": ("error", f"districts overlap another jurisdiction (>= {OVERLAP_ERROR_ACRES} ac)"),
    "value_out_of_range": ("error", "compiled standard outside plausible range"),
    "research_rule_violation": ("error", "research row breaks a recording rule"),
    "code_not_in_code_list": ("error", "compiled code missing from zoning_codes.csv"),
    "clipped_into_other_jurisdiction": ("warn", f"zoning clipped off inside another jurisdiction (pieces >= {SPILL_REVIEW_ACRES} ac)"),
    "high_unzoned_share": ("warn", f"more than {UNZONED_WARN_PCT}% of the boundary has no zoning"),
    "low_local_coverage": ("warn", f"local source covers under {LOCAL_COVERAGE_MIN_PCT}% of Regrid zoning"),
    "low_local_agreement": ("warn", "Regrid agreement with local source rated low or medium"),
    "open_research": ("warn", "priority-1 research rows still todo"),
    "retired_code_research": ("warn", "open research rows on retired codes"),
    "density_lot_inconsistent": ("warn", "max density allows < 0.5 unit on a minimum-size lot"),
    "minus9999_density_multifamily": ("warn", "-9999 density left in multifamily/mixed districts without research"),
    "regrid_likely_stale": ("warn", "local layer edited after Regrid zoning date"),
    "baseline_older_than_code": ("warn", "researched code is newer than baseline districts"),
    "base_zoning_gaps": ("warn", f"over {GAP_PARCELS_MIN} parcels and {GAP_PARCELS_PCT}% of parcels in unzoned pieces (>= {GAP_MIN_ACRES} ac)"),
    "overlay_only_zoning": ("warn", "polygons carry an overlay but no base district"),
    "overlay_needs_curation": ("warn", "combined codes with no base_zoning in overlay_codes.csv"),
    "unmatched_parcels": ("warn", f"over {UNMATCHED_PARCELS_WARN_PCT}% of parcels lack a matching zoning_id (DQ-001)"),
}


def _sql(conn, q: str) -> pd.DataFrame:
    return pd.read_sql(text(q), conn)


def geometry_checks(conn) -> pd.DataFrame:
    base = _sql(conn, f"""
        select b.municipality_id,
               count(z.zoning_id) filter (where not st_isvalid(z.geometry)) invalid_geometries
        from {BOUNDARIES} b left join {COMPILED} z using (municipality_id) group by 1""")
    # Uses the compiled table's spatial index; area measured only for candidate pairs
    overlaps = _sql(conn, f"""
        with pairs as (
            select a.municipality_id ma, b.municipality_id mb,
                   st_transform(a.geometry, {AREA_SRID}) ga, st_transform(b.geometry, {AREA_SRID}) gb
            from {COMPILED} a join {COMPILED} b
              on a.zoning_id < b.zoning_id and a.geometry && b.geometry
             and st_intersects(a.geometry, b.geometry)
            where a.layer_role = 'base' and b.layer_role = 'base'),
        o as (select ma, mb, st_area(st_intersection(ga, gb)) area from pairs where st_relate(ga, gb, '2********'))
        select ma as municipality_id,
               coalesce(sum(area) filter (where ma = mb), 0) / {SQ_M_PER_ACRE} self_overlap_acres,
               coalesce(sum(area) filter (where ma <> mb), 0) / {SQ_M_PER_ACRE} cross_overlap_acres
        from o group by 1""")
    unzoned = _sql(conn, f"""
        with u as (select municipality_id, st_union(st_transform(geometry, {AREA_SRID})) g
                   from {COMPILED} where layer_role = 'base' group by 1)
        select b.municipality_id,
               round((100 * st_area(st_difference(st_transform(b.geometry, {AREA_SRID}), coalesce(u.g, 'POLYGON EMPTY'::geometry)))
                      / st_area(st_transform(b.geometry, {AREA_SRID})))::numeric, 1) pct_boundary_unzoned
        from {BOUNDARIES} b left join u using (municipality_id)""")
    log = _sql(conn, f"select municipality_id, polygons_out, polygons_clipped, acres_removed, review_pieces, review_acres from {DB_SCHEMA}.compile_log")
    df = base.merge(log, on="municipality_id", how="left").merge(overlaps, on="municipality_id", how="left")
    df = df.merge(unzoned, on="municipality_id", how="left")
    return df.fillna({"self_overlap_acres": 0, "cross_overlap_acres": 0})


def code_checks(conn) -> pd.DataFrame:
    codes = pd.read_csv(INVENTORY_DIR / "zoning_codes.csv", dtype={"zoning": str}, keep_default_na=False)
    research = pd.read_csv(INVENTORY_DIR / "standards_research.csv", dtype=str, keep_default_na=False)
    research["municipality_id"] = research.municipality_id.astype(int)
    compiled_codes = _sql(conn, f"select distinct municipality_id, zoning from {COMPILED}")

    known = compiled_codes.merge(codes[["municipality_id", "zoning", "code_status"]],
                                 on=["municipality_id", "zoning"], how="left")
    missing = known[known.code_status.isna()].groupby("municipality_id").size().rename("codes_not_in_list")

    p1 = research[research.priority == "1"]
    open_p1 = p1[p1.status == "todo"].groupby("municipality_id").size().rename("open_research_p1")
    drafted = research[research.status == "drafted"].groupby("municipality_id").size().rename("drafted_values")
    approved = research[research.status == "approved"].groupby("municipality_id").size().rename("approved_values")

    retired = codes[codes.code_status == "retired"][["municipality_id", "zoning"]]
    retired_open = research.merge(retired, on=["municipality_id", "zoning"])
    retired_open = retired_open[retired_open.status.isin(["todo", "drafted"])].groupby(
        "municipality_id").size().rename("retired_code_research")

    # Recording rules for research rows
    r = research[research.status.isin(["drafted", "approved"])]
    numeric = pd.to_numeric(r.value, errors="coerce")
    bad = (
        ((r.value_type == "not_regulated") & (r.value != ""))
        | ((r.value != "") & numeric.isna())
        | ((r.value != "") & (r.value_type == ""))
        | (r.notes.str.contains("derived", case=False) & (r.conditions == ""))
        | (r.source_url == "")
    )
    violations = r[bad].groupby("municipality_id").size().rename("research_rule_violations")

    return pd.concat([missing, open_p1, drafted, approved, retired_open, violations], axis=1).reset_index().rename(
        columns={"index": "municipality_id"})


def value_checks(conn) -> pd.DataFrame:
    out_of_range = " or ".join(
        f"({f} >= 0 and ({f} < {lo} or {f} > {hi}))" for f, (lo, hi) in RANGES.items())
    subtypes = ", ".join(f"'{s}'" for s in MULTIFAMILY_SUBTYPES)
    df = _sql(conn, f"""
        with c as (select distinct on (municipality_id, zoning) municipality_id, zoning, zoning_type, zoning_subtype,
                          {", ".join(PRIORITY_FIELDS)}
                   from {COMPILED} order by municipality_id, zoning)
        select municipality_id,
               count(*) filter (where {out_of_range}) codes_out_of_range,
               count(*) filter (where max_density_du_per_acre > 0 and min_lot_area_sq_ft > 0
                                  and max_density_du_per_acre * min_lot_area_sq_ft / 43560 < 0.5) codes_density_lot_inconsistent,
               count(*) filter (where max_density_du_per_acre = -9999
                                  and (zoning_subtype in ({subtypes}) or zoning_type = 'Mixed')) codes_minus9999_density_mf,
               count(*) filter (where {" or ".join(f"{f} = -5555" for f in PRIORITY_FIELDS)}) codes_with_5555
        from c group by 1""")
    # -9999 multifamily density counts only where no research row covers it
    research = pd.read_csv(INVENTORY_DIR / "standards_research.csv", dtype=str, keep_default_na=False)
    covered = research[(research.field == "max_density_du_per_acre") & (research.status != "todo")]
    if not covered.empty:
        mf = _sql(conn, f"""
            select distinct municipality_id, zoning from {COMPILED}
            where max_density_du_per_acre = -9999 and (zoning_subtype in ({subtypes}) or zoning_type = 'Mixed')""")
        covered = covered.assign(municipality_id=covered.municipality_id.astype(int))[["municipality_id", "zoning"]]
        mf = mf.merge(covered, how="left", indicator=True)
        uncovered = mf[mf._merge == "left_only"].groupby("municipality_id").size()
        df["codes_minus9999_density_mf"] = df.municipality_id.map(uncovered).fillna(0).astype(int)
    return df


def vintage_checks(conn) -> pd.DataFrame:
    dates = _sql(conn, f"""
        with z as (select municipality_id, max(zoning_data_date) d from {SOURCE_TABLE} group by 1),
             c as (select municipality_id, max(zoning_data_date) d from {COMPARATOR_TABLE} group by 1)
        select b.municipality_id, z.d baseline_date, c.d comparator_date
        from {BOUNDARIES} b left join z using (municipality_id) left join c using (municipality_id)""")
    research = pd.read_csv(INVENTORY_DIR / "standards_research.csv", dtype=str, keep_default_na=False)
    researched = set(research[research.status.isin(["drafted", "approved", "superseded"])].municipality_id.astype(int))
    dates["has_research"] = dates.municipality_id.isin(researched)
    dates["baseline_older_than_code"] = dates.has_research & (dates.comparator_date > dates.baseline_date)

    comp_path = INVENTORY_DIR / "zoning_source_comparison.csv"
    if comp_path.exists():
        comp = pd.read_csv(comp_path)[["municipality_id", "source_last_edit", "regrid_zoning_date",
                                       "pct_regrid_area_covered", "accuracy_rating"]]
        dates = dates.merge(comp, on="municipality_id", how="left")
        dates["regrid_likely_stale"] = pd.to_datetime(dates.source_last_edit) > pd.to_datetime(dates.baseline_date)
    return dates


def parcel_checks(conn) -> pd.DataFrame:
    """Parcels matched to a district by zoning_id; unmatched located by position."""
    conn.execute(text(f"""
        create temp table _bnd_sub_qa on commit drop as
        select municipality_id, st_subdivide(geometry, 256) g from {BOUNDARIES}"""))
    conn.execute(text("create index on _bnd_sub_qa using gist (g)"))
    conn.execute(text(f"""
        create temp table _unmatched on commit drop as
        select st_pointonsurface(p.geometry) pt
        from {PARCELS_TABLE} p left join {SOURCE_TABLE} z on p.zoning_id = z.zoning_id
        where z.zoning_id is null"""))
    conn.execute(text("create index on _unmatched using gist (pt)"))
    return _sql(conn, f"""
        with matched as (
            select z.municipality_id, count(*) n
            from {PARCELS_TABLE} p join {SOURCE_TABLE} z on p.zoning_id = z.zoning_id group by 1),
        unmatched as (
            select b.municipality_id, count(*) n
            from _unmatched u join _bnd_sub_qa b on st_intersects(b.g, u.pt) group by 1)
        select b.municipality_id, coalesce(m.n, 0) parcels_matched, coalesce(u.n, 0) parcels_unmatched,
               round((100.0 * coalesce(u.n, 0) / nullif(coalesce(m.n, 0) + coalesce(u.n, 0), 0))::numeric, 1) pct_parcels_unmatched
        from {BOUNDARIES} b left join matched m using (municipality_id) left join unmatched u using (municipality_id)""")


def base_gap_checks(conn) -> pd.DataFrame:
    """Gaps in base zoning: unzoned pieces that contain parcels, and overlay-only polygons.

    Writes zoning_inventory.base_zoning_gaps (one row per gap piece) for review.
    Unzoned pieces without parcels are treated as streets or water (left unzoned).
    """
    conn.execute(text(f"""
        create temp table _parcel_pts on commit drop as
        select st_pointonsurface(geometry) pt from {PARCELS_TABLE}"""))
    conn.execute(text("create index on _parcel_pts using gist (pt)"))
    conn.execute(text(f"drop table if exists {DB_SCHEMA}.base_zoning_gaps"))
    conn.execute(text(f"""
        create table {DB_SCHEMA}.base_zoning_gaps as
        with u as (select municipality_id, st_union(geometry) g from {COMPILED}
                   where layer_role = 'base' and base_zoning is not null group by 1),
        d as (select b.municipality_id, b.jurisdiction,
                     (st_dump(st_difference(b.geometry, coalesce(u.g, 'POLYGON EMPTY'::geometry)))).geom g
              from {BOUNDARIES} b left join u using (municipality_id)),
        pieces as (select municipality_id, jurisdiction, g,
                          st_area(st_transform(g, {AREA_SRID})) / {SQ_M_PER_ACRE} acres
                   from d where st_area(st_transform(g, {AREA_SRID})) >= {GAP_MIN_ACRES * SQ_M_PER_ACRE})
        select row_number() over (order by p.municipality_id, p.acres desc)::integer as gap_id,
               p.municipality_id, p.jurisdiction, round(p.acres::numeric, 1) as acres,
               count(pt.pt)::integer as parcels, st_multi(p.g)::geometry(MultiPolygon, 4326) as geometry
        from pieces p join _parcel_pts pt on st_intersects(p.g, pt.pt)
        group by p.municipality_id, p.jurisdiction, p.g, p.acres"""))
    gaps = _sql(conn, f"""
        select municipality_id, count(*) gap_pieces, round(sum(acres)::numeric, 1) gap_acres,
               sum(parcels) parcels_in_gaps
        from {DB_SCHEMA}.base_zoning_gaps group by 1""")
    overlay_only = _sql(conn, f"""
        select municipality_id, count(*) overlay_only_polygons,
               round((sum(st_area(st_transform(geometry, {AREA_SRID}))) / {SQ_M_PER_ACRE})::numeric, 1) overlay_only_acres
        from {COMPILED} where base_zoning is null group by 1""")
    oc = pd.read_csv(INVENTORY_DIR / "overlay_codes.csv", keep_default_na=False)
    curation = oc[oc.base_zoning == ""].groupby("municipality_id").size().rename("overlay_codes_need_curation").reset_index()
    links = _sql(conn, f"""
        select z.municipality_id, count(distinct l.overlay_id) overlay_districts
        from {DB_SCHEMA}.zoning_overlay_links l join {COMPILED} z using (zoning_id) group by 1""")
    out = gaps
    for part in (overlay_only, curation, links):
        out = out.merge(part, on="municipality_id", how="outer")
    return out


def flags_for(row) -> list[str]:
    f = []
    if row.invalid_geometries > 0: f.append("invalid_geometry")
    if row.self_overlap_acres >= OVERLAP_ERROR_ACRES: f.append("base_self_overlap")
    if row.cross_overlap_acres >= OVERLAP_ERROR_ACRES: f.append("cross_jurisdiction_overlap")
    if row.codes_out_of_range > 0: f.append("value_out_of_range")
    if row.research_rule_violations > 0: f.append("research_rule_violation")
    if row.codes_not_in_list > 0: f.append("code_not_in_code_list")
    if row.review_pieces > 0: f.append("clipped_into_other_jurisdiction")
    if row.pct_boundary_unzoned > UNZONED_WARN_PCT: f.append("high_unzoned_share")
    if pd.notna(row.get("pct_regrid_area_covered")) and row.pct_regrid_area_covered < LOCAL_COVERAGE_MIN_PCT:
        f.append("low_local_coverage")
    if row.get("accuracy_rating") in ("low", "medium"): f.append("low_local_agreement")
    if row.open_research_p1 > 0: f.append("open_research")
    if row.retired_code_research > 0: f.append("retired_code_research")
    if row.codes_density_lot_inconsistent > 0: f.append("density_lot_inconsistent")
    if row.codes_minus9999_density_mf > 0: f.append("minus9999_density_multifamily")
    if row.get("regrid_likely_stale") is True: f.append("regrid_likely_stale")
    if row.baseline_older_than_code: f.append("baseline_older_than_code")
    if row.pct_parcels_unmatched > UNMATCHED_PARCELS_WARN_PCT: f.append("unmatched_parcels")
    total = row.parcels_matched + row.parcels_unmatched
    if row.parcels_in_gaps > GAP_PARCELS_MIN and total and 100 * row.parcels_in_gaps / total > GAP_PARCELS_PCT:
        f.append("base_zoning_gaps")
    if row.overlay_only_polygons > 0: f.append("overlay_only_zoning")
    if row.overlay_codes_need_curation > 0: f.append("overlay_needs_curation")
    return f


def run() -> pd.DataFrame:
    engine = get_engine()
    with engine.begin() as conn:
        names = _sql(conn, f"select municipality_id, jurisdiction, geoid, is_unincorporated from {BOUNDARIES}")
        df = names
        for check in (geometry_checks, code_checks, value_checks, vintage_checks, parcel_checks,
                      base_gap_checks):
            t0 = time.time()
            df = df.merge(check(conn), on="municipality_id", how="left")
            print(f"  {check.__name__}: {time.time() - t0:.0f}s", flush=True)
        count_cols = ["codes_not_in_list", "open_research_p1", "drafted_values", "approved_values",
                      "retired_code_research", "research_rule_violations", "codes_out_of_range",
                      "codes_density_lot_inconsistent", "codes_minus9999_density_mf", "codes_with_5555",
                      "gap_pieces", "parcels_in_gaps", "overlay_only_polygons", "overlay_codes_need_curation",
                      "overlay_districts"]
        df[count_cols] = df[count_cols].fillna(0).astype(int)
        df["flags"] = df.apply(lambda r: "; ".join(flags_for(r)), axis=1)
        df["errors"] = df["flags"].map(lambda s: sum(FLAGS[f][0] == "error" for f in s.split("; ") if f))
        df["warnings"] = df["flags"].map(lambda s: sum(FLAGS[f][0] == "warn" for f in s.split("; ") if f))
        df["qa_status"] = df.apply(lambda r: "fail" if r.errors else ("warn" if r.warnings else "pass"), axis=1)
        df["qa_run_on"] = pd.Timestamp.today().date()
        for c in ("self_overlap_acres", "cross_overlap_acres"):
            df[c] = df[c].astype(float).round(2)

        df.to_sql("qa_report", conn, schema=DB_SCHEMA, if_exists="replace", index=False)
        conn.execute(text(f"""
            update {COMPILED} z set qa_status = q.qa_status
            from {DB_SCHEMA}.qa_report q where q.municipality_id = z.municipality_id"""))
    df.sort_values("jurisdiction").to_csv(INVENTORY_DIR / "qa_report.csv", index=False)
    return df


def main() -> None:
    df = run()
    print(df.qa_status.value_counts().to_string())
    counts = pd.Series([f for s in df["flags"] for f in s.split("; ") if f]).value_counts()
    print("\nflags (jurisdictions):")
    for f, n in counts.items():
        print(f"  {FLAGS[f][0]:5}  {f:32} {n:3}  {FLAGS[f][1]}")


if __name__ == "__main__":
    main()
