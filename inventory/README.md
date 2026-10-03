# Regional zoning jurisdiction inventory

Tracks, for every Bay Area jurisdiction and zoning code, where Regrid's
standardized zoning needs local research, and records that research with
sources. The first focus is resolving Regrid's `-5555` values for the
housing-capacity standards.

## Files

| File | Rows | Edited by hand? |
|---|---|---|
| `jurisdictions.csv` | One per jurisdiction (109 in region + 2 border slivers) | Partly: `official_code_url`, `local_zoning_gis_url`, `status`, `notes` |
| `zoning_codes.csv` | One per jurisdiction + zoning code (6,709) | No, fully regenerated |
| `standards_research.csv` | Research queue: one per code + standard where Regrid has `-5555` | Yes: the research columns below |
| `SOURCE.txt` | Which Regrid table and date the files were built from | No |

Regenerate from the database (hand edits are kept; matched on
`municipality_id` + `zoning` + `field`):

```bash
python -m regional_zoning.inventory build                 # default: regrid_raw_202512.zoning_union (baseline)
python -m regional_zoning.inventory build regrid_raw_YYYYMM.zoning_union
python -m regional_zoning.inventory load                  # copy CSVs to Postgres schema zoning_inventory
```

Researched rows are kept even if a later Regrid extract fills in the value, so
the two can be compared.

## Regrid placeholder codes

From Regrid's [Standardized Zoning documentation](https://support.regrid.com/docs/standardized-zoning):

- **`-5555`**: "Refer to the zoning code for details." The standard exists
  but is too complex for one value. **These are in the research queue.**
- **`-9999`**: "Not applicable to this zone." The ordinance does not
  regulate it. Not queued, but spot-check: some look wrong (e.g. Berkeley
  R-1/R-2/R-4 max density, which the code regulates via lot area per unit).

## Priority standards

`max_density_du_per_acre`, `max_building_height_ft`, `max_far`,
`min_lot_area_sq_ft`.

Queue priority (`priority` column): **1** Residential and Mixed districts,
**2** Planned and Special, **3** everything else.

## Research columns (`standards_research.csv`)

| Column | What to record |
|---|---|
| `value` | The base numeric value in the field's units (du/acre, ft, ratio, sq ft). Blank if `value_type` is `not_regulated`. |
| `value_type` | `fixed` (one value), `conditional` (depends on something, record the base case in `value`), `range` (record the maximum allowed in `value`), or `not_regulated`. |
| `conditions` | What the value depends on, in plain words, e.g. "45 ft; 55 ft with ground-floor retail" or "1 unit per 1,500 sq ft of lot area". |
| `source_url` | Direct link to the ordinance section, from the official code, not a vendor summary. |
| `source_section` | Section number, e.g. "BMC 23.202.050 Table 23.202-3". |
| `researched_by` | `claude` or staff initials. |
| `researched_date` | YYYY-MM-DD. |
| `status` | `todo` → `drafted` (researched, not reviewed) → `approved`, or `needs_revision`. |
| `reviewer`, `reviewed_date` | Who approved it and when. Only people approve. |
| `notes` | Anything else: ambiguities, overlays, pending amendments. |

### Conventions

- **Density** expressed as lot area per unit converts as
  `43,560 / sq ft per unit` (e.g. 1 unit / 1,500 sq ft = 29.0 du/acre); note the
  original rule in `conditions`.
- Record **base zoning** values. Note bonuses (State Density Bonus, local
  incentive programs) and overlays in `conditions`, not in `value`.
- `jurisdictions.official_code_url` should be the jurisdiction's own published
  code. For 34 jurisdictions Regrid's link points to a vendor site
  (`regrid_link_is_vendor = True`).

## Local zoning source inventory

`zoning_sources.csv` is the curated registry of each jurisdiction's own
published zoning map layer (publisher, service URL, zone code field,
coordinate override, verification). `zone_code_crosswalk.csv` records codes
that are the same zone under different labels. Compare Regrid with the local
layers:

```bash
python -m regional_zoning.sources discover "City Name"   # candidate layers (needs review)
python -m regional_zoning.sources compare                # all active sources
python -m regional_zoning.sources compare 189 148        # by municipality_id
```

Results go to `zoning_source_comparison.csv`. Downloaded layers are cached in
`data_raw/local_zoning/` (gitignored); only the zone code field and geometry
are downloaded. See `docs/2026-10-02-local-zoning-source-inventory.md`.
