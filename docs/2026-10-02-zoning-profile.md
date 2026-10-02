# Regrid zoning profile — June 2026 extract (2026-10-02)

First look at `regrid_raw_202606.zoning_union`, the newest region-wide Regrid
zoning layer staged in the project database. Regenerate the full tables with:

```bash
python -m regional_zoning.profile_zoning
```

## Summary

- **Coverage is complete at the jurisdiction level.** All 101 Bay Area cities
  and all 8 unincorporated county areas (San Francisco has none) are present: 80,687 district polygons,
  EPSG:4326, no invalid or empty geometries.
- **Vintages vary by jurisdiction.** Zoning data dates run from 2023-07-26
  (Suisun City) to 2026-02-13 (Windsor). 37 of 118 jurisdiction/county rows
  changed since the December 2025 extract.
- **The numeric development standards are sparse.** Every numeric field looks
  100% populated, but most values are the codes `-5555` ("refer to the zoning
  code") or `-9999` ("not applicable"); only `-5555` is a research gap.
  For Residential and Mixed districts,
  region-wide coverage of real values is: max height 59%, min lot area 58%,
  max density 20%, max FAR 8%, min side setback 5%.
- **Coverage differs sharply by county.** For example, max density is real for
  67% of Solano residential polygons but 4% in Alameda and 0% in San Francisco;
  max FAR is real for 69% in San Francisco but 1–16% elsewhere. Filling these
  gaps from local ordinances is the main standardization job.
- **The text and category fields are fully populated:** `zoning`,
  `zoning_description`, `zoning_type`/`zoning_subtype`, and `zoning_code_link`.
  `zoning_type` gives a usable first-cut regional classification.

## Placeholder codes

The codes appear in all 12 numeric standards fields:

| field | -5555 | -9999 | real (>= 0) |
|:--|--:|--:|--:|
| min_lot_area_sq_ft | 28,380 | 12,859 | 39,448 |
| max_building_height_ft | 29,588 | 9,892 | 41,207 |
| max_far | 17,421 | 53,580 | 9,686 |
| max_density_du_per_acre | 14,125 | 55,524 | 11,038 |
| max_coverage_pct | 15,898 | 44,766 | 20,023 |
| min_side_setback_ft | 56,675 | 19,815 | 4,197 |

Regrid's [Standardized Zoning documentation](https://support.regrid.com/docs/standardized-zoning)
defines the codes:

- **`-5555` — "Refer to the zoning code for details."** The standard exists but
  is too complex for a single value (it varies by lot size, use, conditions,
  etc.). These are the real research gaps.
- **`-9999` — "Not applicable to this zone."** The ordinance does not regulate
  that standard. This is information, not missing data, though it is worth
  spot-checking.

Values are identical across all polygons that share a jurisdiction and zoning
code, so research can be done per code: 6,709 jurisdiction/code
combinations, of which 5,200 have at least one `-5555`.

## Zoning categories

| zoning_type | polygons | sq mi |
|:--|--:|--:|
| Residential | 41,465 | 659 |
| Planned | 11,104 | 556 |
| Special | 10,544 | 2,014 |
| Commercial | 7,443 | 61 |
| Mixed | 4,959 | 175 |
| Agriculture | 2,011 | 3,456 |
| Industrial | 1,739 | 133 |
| Overlay | 1,422 | 38 |

Residential subtypes: Single Family (26,634), Multi Family (11,220), Two Family
(3,611). **Overlay** polygons sit in the same layer as base districts, so they
overlap base zoning and must be separated before any parcel join or area total.
**Planned** and **Special** districts (21,648 polygons) carry little
standardized detail and will usually need the local ordinance or plan.

## Data quality notes

- **Cross-county slivers:** a few jurisdictions show up under a neighboring
  county's `geoid` with near-zero area (e.g. Oakland in Contra Costa, Milpitas
  in Alameda, Daly City in San Francisco), and three out-of-region
  unincorporated areas appear as single slivers (Santa Cruz, Mendocino, and
  Sonoma County Unincorporated under Marin). Treat these as edge artifacts.
- **Area-weighted coverage is misleading:** large rural unincorporated and
  agricultural zones dominate area totals, so coverage is reported per polygon
  for Residential/Mixed districts above.
- **Code counts vary widely:** e.g. San Jose has 11,794 polygons but 56
  distinct codes, while Fremont has 480 codes and San Francisco 841, so
  district naming conventions differ a lot between jurisdictions.

## Suggested next steps

- [x] Confirm the meaning of `-5555` and `-9999` (see Placeholder codes above).
- [ ] Separate overlay districts from base zoning and check for gaps/overlaps
      in base zoning coverage.
- [x] Start the jurisdiction inventory (`inventory/`): one row per
      jurisdiction with Regrid vintage, local source, and coverage of key
      standards, using the tables from `profile_zoning`.
- [ ] Pick a few pilot jurisdictions with low coverage (e.g. Alameda County
      cities for density) to compare against local ordinances.
