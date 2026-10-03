# Batch 3: in progress (2026-10-03)

Jurisdictions: Lafayette, Brentwood, Newark, Petaluma, Calistoga, Tiburon,
Sausalito, San Anselmo, Hillsborough, Gilroy. First batch run in the new
pipeline order (source → compare → compile → research → QA). Development
baseline: `regrid_raw_202512`. 78 priority-1 research rows plus 20 `-9999`
density checks in multifamily and mixed-use districts.

## Step 1-2: sources and comparison (done)

| Jurisdiction | Local source | Agreement (excl. slivers) | Rating | Notes |
|---|---|--:|---|---|
| San Anselmo | Marin County Open Data (2025-02-10) | 100% | high | |
| Tiburon | Marin County Open Data (2023-03-29) | 100% | high | After crosswalk: `M` = `Marine`, `P-R` = `P and R` |
| Petaluma | City ArcGIS Server, "Zoning (2008)" | 99.9% | high | Regrid also has Central Petaluma Specific Plan codes the city layer lacks (Regrid more current) |
| Sausalito | Marin County Open Data (2023-03-29) | 99.1% | coverage gap | Local layer covers 75% of Regrid area |
| Calistoga | Napa County GIS, parcel-based (2026-02-13) | 97.4% | medium | Local generalizes numbered PD districts to `PD` (crosswalk); RR-H → PD on 30 ac (likely recent rezoning) |
| Lafayette, Brentwood, Newark, Gilroy, Hillsborough | none found | | | Registered as `none_found` with notes |

No local codes were missing from the Regrid code list, so research proceeds
on the baseline codes.

## Step 4: research

| Jurisdiction | Status | Notes |
|---|---|---|
| Hillsborough | **Drafted** (9 values + 1 correction) | Districts RD-1/2/3 since Ord. 792 (2024). Town-wide height envelope 22 ft rising to 32 ft; FAR 0.25 (single-family only); RD-2 min density 20 du/ac with no max (Regrid `-9999` correct); RD-3 capped at 16 units |
| Lafayette | **Drafted** (6 values) | Multifamily density defers to the General Plan / Housing Element Program 10.3.g (Ord. 696, 2025) except MRB (2,500 sq ft per unit = 17.4 du/ac). Density checks D-1 and MRP not done |
| Petaluma | Started | Standards are in IZO Chapter 4, Tables 4.8 (R2/R3), 4.9 (R4/R5), 4.10 (MU1/MU2) at petaluma.municipal.codes/ZoningOrds/4 |
| Brentwood, Calistoga, Gilroy, Newark, Sausalito, San Anselmo, Tiburon | Not started | Official codes: see `inventory/jurisdictions.csv` / `zoning_sources.csv`; Tiburon, Sausalito, San Anselmo, Newark have vendor links in Regrid |

## Remaining

1. Research the 8 remaining jurisdictions and the open density checks.
2. Re-run `compile` and `qa`; write the batch report.
