"""Regional zoning jurisdiction inventory.

Builds and maintains three CSV files in `inventory/` from a Regrid zoning
union table, and loads them into Postgres:

- `jurisdictions.csv`: one row per jurisdiction. Regrid-derived columns are
  regenerated; the hand-edited columns (official ordinance URL, notes, etc.)
  are kept across rebuilds.
- `zoning_codes.csv`: one row per jurisdiction + zoning code, with Regrid's
  values for the priority standards. Fully regenerated.
- `standards_research.csv`: the research queue. One row per zoning code and
  priority standard where Regrid has -5555 ("refer to the zoning code").
  New rows are added on rebuild; existing rows and their research are kept.

Usage:
    python -m regional_zoning.inventory build [schema.table]
    python -m regional_zoning.inventory load
"""

import sys
from datetime import date

import pandas as pd
from sqlalchemy import Boolean, Date, text

from regional_zoning.db import REPO_ROOT, get_engine

# Baseline vintage: matches the regrid_basis_202512 derived products
SOURCE_TABLE = "regrid_raw_202512.zoning_union"
INVENTORY_DIR = REPO_ROOT / "inventory"
DB_SCHEMA = "zoning_inventory"

# Regrid placeholder codes (https://support.regrid.com/docs/standardized-zoning)
REFER_TO_CODE = -5555  # standard exists but is too complex for one value
NOT_APPLICABLE = -9999  # ordinance does not regulate this standard

# Housing-capacity standards, researched first
PRIORITY_FIELDS = [
    "max_density_du_per_acre",
    "max_building_height_ft",
    "max_far",
    "min_lot_area_sq_ft",
]

# 1 = researched first
PRIORITY_BY_TYPE = {"Residential": 1, "Mixed": 1, "Planned": 2, "Special": 2}
DEFAULT_PRIORITY = 3

# Out-of-region unincorporated slivers along the Bay Area border
OUT_OF_REGION = {"Santa Cruz County Unincorporated", "Mendocino County Unincorporated"}

CODE_KEY = ["municipality_id", "zoning"]
RESEARCH_KEY = CODE_KEY + ["field"]

JURISDICTION_EDIT_COLUMNS = [
    "official_code_url",
    "local_zoning_gis_url",
    "status",
    "notes",
]

RESEARCH_EDIT_COLUMNS = [
    "value",  # base numeric value, in the field's units
    "value_type",  # fixed | conditional | range | not_regulated
    "conditions",  # what the value depends on, e.g. lot size, use, bonus
    "source_url",
    "source_section",
    "researched_by",
    "researched_date",
    "status",  # todo | drafted | approved | needs_revision | superseded
    "reviewer",
    "reviewed_date",
    "notes",
]


def _codes(table: str) -> pd.DataFrame:
    fields = ", ".join(f"max({f}) as {f}" for f in PRIORITY_FIELDS)
    return pd.read_sql(
        f"""
        select municipality_id, max(municipality_name) jurisdiction,
               -- the county holding most of the code's area; drops cross-county slivers
               (array_agg(geoid order by st_area(geometry::geography) desc))[1] geoid,
               zoning, max(zoning_type) zoning_type, max(zoning_subtype) zoning_subtype,
               max(zoning_description) zoning_description,
               count(*) polygons,
               round((sum(st_area(geometry::geography)) / 2589988.11)::numeric, 3) sq_mi,
               max(zoning_data_date) zoning_data_date,
               max(zoning_code_link) regrid_code_link,
               {fields}
        from {table}
        group by municipality_id, zoning
        order by geoid, jurisdiction, zoning
        """,
        get_engine(),
    )


def build_zoning_codes(codes: pd.DataFrame) -> pd.DataFrame:
    df = codes.copy()
    df["in_region"] = ~df.jurisdiction.isin(OUT_OF_REGION)
    df["priority"] = df.zoning_type.map(PRIORITY_BY_TYPE).fillna(DEFAULT_PRIORITY).astype(int)
    return df


def build_jurisdictions(codes: pd.DataFrame, existing: pd.DataFrame | None) -> pd.DataFrame:
    g = codes.groupby("municipality_id")
    df = pd.DataFrame(
        {
            "jurisdiction": g.jurisdiction.first(),
            "geoid": g.geoid.agg(lambda s: s.mode().iloc[0]),
            "in_region": g.in_region.first(),
            "zoning_codes": g.size(),
            "polygons": g.polygons.sum(),
            "sq_mi": g.sq_mi.sum().round(1),
            "zoning_data_date": g.zoning_data_date.max(),
            "regrid_code_link": g.regrid_code_link.first(),
            "regrid_link_is_vendor": g.regrid_code_link.first().str.contains("zoneomics", na=False),
        }
    )
    for f in PRIORITY_FIELDS:
        df[f"codes_{f}_5555"] = g[f].agg(lambda s: int((s == REFER_TO_CODE).sum()))
    df = df.reset_index()
    for c in JURISDICTION_EDIT_COLUMNS:
        df[c] = ""
    df["status"] = "not_started"
    return _keep_edits(df, existing, ["municipality_id"], JURISDICTION_EDIT_COLUMNS)


def build_research_queue(codes: pd.DataFrame, existing: pd.DataFrame | None) -> pd.DataFrame:
    context = ["geoid", "jurisdiction", "zoning_type", "zoning_subtype", "zoning_description",
               "polygons", "sq_mi", "priority", "regrid_code_link"]
    long = codes.melt(id_vars=CODE_KEY + context, value_vars=PRIORITY_FIELDS,
                      var_name="field", value_name="regrid_value")
    in_region = codes.set_index(CODE_KEY).in_region
    long = long[long.set_index(CODE_KEY).index.map(in_region)]
    df = long[long.regrid_value == REFER_TO_CODE].copy()
    for c in RESEARCH_EDIT_COLUMNS:
        df[c] = ""
    df["status"] = "todo"
    df = _keep_edits(df, existing, RESEARCH_KEY, RESEARCH_EDIT_COLUMNS)
    if existing is not None:
        # Keep researched rows even if Regrid has since filled in the value
        gone = existing.merge(df[RESEARCH_KEY], on=RESEARCH_KEY, how="left", indicator=True)
        gone = gone[(gone._merge == "left_only") & (gone.status != "todo")].drop(columns="_merge")
        df = pd.concat([df, gone], ignore_index=True)
    field_order = {f: i for i, f in enumerate(PRIORITY_FIELDS)}
    return df.sort_values(
        ["priority", "geoid", "jurisdiction", "zoning", "field"],
        key=lambda s: s.map(field_order) if s.name == "field" else s,
    )


def _keep_edits(new: pd.DataFrame, existing: pd.DataFrame | None, key: list[str],
                edit_cols: list[str]) -> pd.DataFrame:
    """Carry hand-edited columns over from the existing CSV, matched on key."""
    if existing is None or existing.empty:
        return new
    merged = new.drop(columns=edit_cols).merge(existing[key + edit_cols], on=key, how="left")
    for c in edit_cols:
        # Rows with no earlier edits keep the new defaults (e.g. status = todo)
        merged[c] = merged[c].fillna(pd.Series(new[c].to_numpy(), index=merged.index))
    return merged[new.columns]


def _read(name: str) -> pd.DataFrame | None:
    path = INVENTORY_DIR / name
    if not path.exists():
        return None
    return pd.read_csv(path, dtype={"geoid": str, "zoning": str}, keep_default_na=False)


def build(table: str = SOURCE_TABLE) -> None:
    codes = _codes(table)
    outputs = {
        "zoning_codes.csv": build_zoning_codes(codes),
        "jurisdictions.csv": build_jurisdictions(
            build_zoning_codes(codes), _read("jurisdictions.csv")
        ),
        "standards_research.csv": build_research_queue(
            build_zoning_codes(codes), _read("standards_research.csv")
        ),
    }
    INVENTORY_DIR.mkdir(exist_ok=True)
    for name, df in outputs.items():
        df.to_csv(INVENTORY_DIR / name, index=False)
        print(f"{name}: {len(df):,} rows")
    (INVENTORY_DIR / "SOURCE.txt").write_text(f"Built from {table} on {date.today()}\n")


INTEGER_COLUMNS = ["municipality_id", "polygons", "priority", "zoning_codes"]
NUMERIC_COLUMNS = ["sq_mi", "regrid_value", "value"] + PRIORITY_FIELDS
DATE_COLUMNS = ["zoning_data_date", "researched_date", "reviewed_date"]
BOOLEAN_COLUMNS = ["in_region", "regrid_link_is_vendor"]


def _typed(df: pd.DataFrame) -> pd.DataFrame:
    """Convert CSV text columns to proper types; blank cells become NULL."""
    df = df.replace("", None)
    for c in df.columns:
        if c in INTEGER_COLUMNS or c.startswith("codes_"):
            df[c] = pd.to_numeric(df[c]).astype("Int64")
        elif c in NUMERIC_COLUMNS:
            df[c] = pd.to_numeric(df[c])
        elif c in DATE_COLUMNS:
            df[c] = pd.to_datetime(df[c]).dt.date
        elif c in BOOLEAN_COLUMNS:
            df[c] = df[c].astype(str).map({"True": True, "False": False}).astype("boolean")
    return df


def load() -> None:
    """Replace the zoning_inventory schema's tables with the CSV contents."""
    engine = get_engine()
    with engine.begin() as conn:
        conn.execute(text(f"create schema if not exists {DB_SCHEMA}"))
    for name in ["jurisdictions", "zoning_codes", "standards_research"]:
        df = _typed(_read(f"{name}.csv"))
        # Explicit types for columns pandas can't infer when they are all NULL
        dtype = {c: Date() for c in DATE_COLUMNS if c in df}
        dtype.update({c: Boolean() for c in BOOLEAN_COLUMNS if c in df})
        df.to_sql(name, engine, schema=DB_SCHEMA, if_exists="replace", index=False, dtype=dtype)
        print(f"{DB_SCHEMA}.{name}: {len(df):,} rows")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "build":
        build(*sys.argv[2:3])
    elif cmd == "load":
        load()
    else:
        sys.exit(__doc__)
