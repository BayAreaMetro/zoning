"""Profile a Regrid zoning union table.

Usage:
    python -m regional_zoning.profile_zoning [schema.table] [compare_schema.table]

Defaults to the June 2026 extract, compared against December 2025. Prints
markdown tables: jurisdiction coverage, placeholder-code counts, real-value
coverage for residential/mixed districts, and changes between extracts.

Regrid uses -5555 and -9999 as placeholder codes in the numeric standards
fields, so only values >= 0 are counted as real.
"""

import sys

import pandas as pd

from regional_zoning.db import get_engine

DEFAULT_TABLE = "regrid_raw_202606.zoning_union"
DEFAULT_COMPARE = "regrid_raw_202512.zoning_union"

PLACEHOLDER_CODES = (-5555, -9999)

NUMERIC_FIELDS = [
    "min_lot_area_sq_ft",
    "min_lot_width_ft",
    "max_building_height_ft",
    "max_far",
    "min_front_setback_ft",
    "min_rear_setback_ft",
    "min_side_setback_ft",
    "max_coverage_pct",
    "max_density_du_per_acre",
    "max_impervious_coverage_pct",
    "min_landscaped_space_pct",
    "min_open_space_pct",
]

SQ_M_PER_SQ_MI = 2589988.11


def jurisdiction_summary(table: str) -> pd.DataFrame:
    """Polygons, distinct codes, data date, and zoned area per county/jurisdiction."""
    return pd.read_sql(
        f"""
        select geoid, municipality_name, count(*) polygons,
               count(distinct zoning) codes,
               max(zoning_data_date) zoning_data_date,
               round((sum(st_area(geometry::geography)) / {SQ_M_PER_SQ_MI})::numeric, 1) sq_mi
        from {table} group by 1, 2 order by 1, 2
        """,
        get_engine(),
    )


def placeholder_counts(table: str) -> pd.DataFrame:
    """Polygon counts per numeric field: each placeholder code vs. real values."""
    cols = ", ".join(
        f"count(*) filter (where {f} = {code}) as \"{f}|{code}\""
        for f in NUMERIC_FIELDS
        for code in PLACEHOLDER_CODES
    )
    cols += ", " + ", ".join(
        f"count(*) filter (where {f} >= 0) as \"{f}|real\"" for f in NUMERIC_FIELDS
    )
    row = pd.read_sql(f"select {cols} from {table}", get_engine()).iloc[0]
    df = pd.DataFrame(
        [k.split("|") + [v] for k, v in row.items()], columns=["field", "value", "polygons"]
    )
    return df.pivot(index="field", columns="value", values="polygons").loc[NUMERIC_FIELDS]


def residential_coverage(table: str) -> pd.DataFrame:
    """% of Residential/Mixed polygons with a real value, by county."""
    fields = NUMERIC_FIELDS[:9]
    cols = ", ".join(f"round(100.0 * avg(({f} >= 0)::int), 0) as \"{f}\"" for f in fields)
    return pd.read_sql(
        f"""
        select coalesce(geoid, 'ALL') geoid, count(*) polygons, {cols}
        from {table} where zoning_type in ('Residential', 'Mixed')
        group by rollup(geoid) order by geoid
        """,
        get_engine(),
    ).set_index("geoid")


def compare_extracts(table: str, compare: str) -> pd.DataFrame:
    """Jurisdictions whose polygon count or zoning data date changed between extracts."""
    q = "select geoid, municipality_name, count(*) polygons, max(zoning_data_date) zoning_data_date from {} group by 1, 2"
    old = pd.read_sql(q.format(compare), get_engine())
    new = pd.read_sql(q.format(table), get_engine())
    df = old.merge(new, on=["geoid", "municipality_name"], how="outer", suffixes=("_old", "_new"))
    changed = (df.polygons_old != df.polygons_new) | (df.zoning_data_date_old != df.zoning_data_date_new)
    return df[changed].sort_values(["geoid", "municipality_name"])


def main() -> None:
    table = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_TABLE
    compare = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_COMPARE
    print(f"# Zoning profile: {table}\n")
    print("## Jurisdictions\n")
    print(jurisdiction_summary(table).to_markdown(index=False))
    print("\n## Placeholder codes in numeric fields (polygon counts)\n")
    print(placeholder_counts(table).to_markdown())
    print("\n## % of Residential/Mixed polygons with a real value\n")
    print(residential_coverage(table).T.to_markdown())
    print(f"\n## Changes since {compare}\n")
    print(compare_extracts(table, compare).to_markdown(index=False))


if __name__ == "__main__":
    main()
