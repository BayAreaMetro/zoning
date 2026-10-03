# Regional zoning dataset: project work plan

Living plan for the `regional-zoning` branch. Dated notes in `docs/` record
individual research steps; this document describes how the work fits
together. Last updated 2026-10-02.

## Goal

A documented, current regional zoning dataset for the 109 Bay Area
jurisdictions (101 cities and 8 unincorporated county areas), built from Regrid
standardized zoning and checked against each jurisdiction's own published zoning,
with provenance for every polygon and every development standard.

## Baseline vintage (decided 2026-10-02)

The **development baseline** is **`regrid_raw_202512`** (`zoning_union`,
`parcels_union`), because its vintage matches the `regrid_basis_202512`
derived products. `regrid_raw_202606` becomes the baseline only after its
build is confirmed; until then district polygons come from December 2025, and
June 2026 polygons are not mixed in (whole-jurisdiction replacement applies
when the baseline changes). The
inventory, research queue, and comparisons are built from it
(`inventory.SOURCE_TABLE`). `regrid_raw_202606` is used as a comparator to see
what changed after the baseline. The December and June `zoning_union` tables
have the same 28 columns (names, types, meanings); only column order and the
`objectid` integer width differ.

**Research and baseline vintages (decided).** Standards research describes
each jurisdiction's *current* zoning code, not the code in effect at the
baseline date, while baseline districts reflect
Regrid's December 2025 data, which for some jurisdictions is older (Regrid
zoning dates back to 2023). Of the 20 jurisdictions researched so far, 9 had
Regrid updates between December and June (Berkeley, Monte Sereno, Napa,
Oakley, Piedmont, Rio Vista, Rohnert Park, Sonoma, Windsor). For these the
QA vintage check flags **"baseline older than code"**; they are reconciled
when the next baseline is adopted. Example:
December's Berkeley data (2025-09-01) predates the middle-housing rezoning
(it still has R-1A; `MUR` instead of `MU-R`).

Research rows written against the June extract were reconciled to the
baseline: 114 still apply, 4 Napa rows became `-9999` corrections, and 13
were marked **`superseded`** (kept, with a note): 9 where December already
has a real value (research agrees in 8; Sonoma MX FAR differs: 0.6 vs a
0.60-1.20 range) and 4 Berkeley MU-R rows (code not in December).

### Adopting the June 2026 build

Before `regrid_raw_202606` replaces the development baseline:

1. **Confirm the build** (staff): the extract is complete and loaded as
   intended. Issues already seen in it:
   - **Missing zoning polygons:** Contra Costa parcels referencing missing
     `zoning_id`s rise from 24.6% (Dec) to 39.3% (Jun); Marin from 0% to 8.8%.
   - **Lost standards:** 8 values that are real in December are `-5555` in
     June (e.g. Monte Sereno minimum lot sizes).
   - **IDs change:** 45% of June `zoning_id`s are new, so parcel joins must
     use June parcels with June zoning.
2. **Switch** `inventory.SOURCE_TABLE` to `regrid_raw_202606.zoning_union` and
   rebuild. Research carries over by `municipality_id` + `zoning`; rows whose
   code or Regrid value changed are re-checked (`superseded` rows can
   reactivate).
3. **Replace polygons whole-jurisdiction**: every jurisdiction takes all its
   districts from the new extract; none are patched.
4. **Re-run** source comparisons, boundary clipping, and QA; clear "baseline
   older than code" flags that the new extract resolves.

## Work streams

| Stream | Question it answers | Main files |
|---|---|---|
| **A. Standards research** | What are the real development standards (density, height, FAR, minimum lot area) for each current zoning code? Resolves Regrid `-5555` ("refer to code") and checks `-9999` ("not applicable"). | `inventory/standards_research.csv`, `inventory/zoning_codes.csv` |
| **B. Local source inventory** | What does each jurisdiction's own, current zoning map say, and how well does Regrid match it? | `inventory/zoning_sources.csv`, `inventory/zone_code_crosswalk.csv`, `inventory/zoning_source_comparison.csv` |

Both streams join on **jurisdiction + zoning code** (`municipality_id`,
`zoning`), linked through the crosswalk.

**Why B runs first for each jurisdiction:** standards research must target
the codes that are actually in force.

- **Milpitas:** Regrid still carries codes that Milpitas's zoning code update
  replaced (MXD, C2, HS → MS-MU, XR-MU, MHP), so researching them would be
  wasted effort.
- **Napa:** codes flagged in Stream A as "not in the zoning code" (MU-CH,
  MU-CL, MU-R) appear on 278 parcels in the city's September 2026 zoning map.
  They are current zones whose ordinance text had not yet been codified
  online.

## Pipeline (per jurisdiction)

| Step | What happens | Stream | Output |
|---|---|---|---|
| 1. Verify source | Find and confirm the jurisdiction's official zoning map layer and zoning code; record adoption date or ordinance | B | `zoning_sources.csv`; `jurisdictions.official_code_url` |
| 2. Compare | Automated overlay of Regrid against the local layer: coverage, code agreement, substantive differences, rating | B | `zoning_source_comparison.csv` |
| 3. **Compile** | Build the jurisdiction's current code list and geometry, clipped to its boundary, with base zoning separated from overlays (see below) | A + B | `zoning_compiled` (PostGIS); `zoning_codes.csv` with `code_status`, `layer_role` |
| 4. Research standards | Fill `-5555` and check `-9999` values for **current codes only** | A | `standards_research.csv` (`drafted`) |
| 5. **QA/QC** | Automated checks, then human review of geometry and standards together | A + B | statuses → `approved` / `needs_revision`; QA report |
| 6. Publish | Load to the `zoning_inventory` schema; produce the regional layer with provenance | A + B | regional zoning table and summary |

### Jurisdiction status

Tracked in `inventory/jurisdictions.csv` (`status`):

`not_started → source_verified → compared → compiled → standards_drafted → qa_passed → approved → published`

A jurisdiction **reopens** when its local layer's edit date changes, a new
Regrid extract is loaded, or a new zoning ordinance is recorded. Only changed
codes and areas repeat steps 3-5.

## Compile step

### Code reconciliation

For each Regrid code in a jurisdiction:

| Outcome | Meaning | Action |
|---|---|---|
| **same** | Code matches the local layer (after punctuation normalization and crosswalk) | Keep Regrid geometry and standards |
| **renamed** | Same zone, different label (e.g. San Jose `W` = `WATER`) | Add crosswalk row; keep standards |
| **replaced** | Area was rezoned | Use local code; mark Regrid code `retired`; queue new code for research |
| **new** | Local code not in Regrid | Add to code list; queue for research |

Research rows on retired codes are kept and marked `superseded`, not
deleted.

### Geometry (decided 2026-10-02)

- **District boundaries are Regrid zones.** The master layer is Regrid's
  zoning district polygons (baseline `regrid_raw_202512.zoning_union`), one base
  zoning layer per jurisdiction with no overlaps. Local layers are used to
  verify codes and currency, not as geometry.
- **Parcels join to districts by key, not by overlay.** Regrid parcels
  (`parcels_union` in the baseline schema, keyed by `ll_uuid`) carry the `zoning_id` of their base
  zoning district in the same extract. Parcel zoning is derived through that
  key; a spatial (largest-overlap) assignment is used only as a fallback for
  parcels whose key is missing or unmatched (see Source and input issues).
- **Replacement is whole-jurisdiction only.** When a jurisdiction's zoning is
  updated (a newer Regrid extract, or an approved local replacement for a
  jurisdiction Regrid has not caught up with, such as Milpitas), all of that
  jurisdiction's districts are replaced together; districts are never patched
  area by area.
- **Working CRS:** California Albers (EPSG:3310) for area and topology
  operations; geometries made valid and snapped to a 1 cm grid before
  clipping. The compiled table gets a spatial (GiST) index (`zoning_union`
  has none).

### Schema (decided 2026-10-02)

The compiled dataset uses **Regrid's zoning schema** (the 28 columns of
`zoning_union`: `zoning_id`, `zoning`, `zoning_description`, `zoning_type`,
`zoning_subtype`, ..., the numeric standards, `zoning_data_date`,
`municipality_id`, `municipality_name`, `geoid`, `geometry`) for every
jurisdiction, with the same names, types, and meanings. Researched standards
are written into Regrid's own numeric fields, replacing `-5555` (and
incorrect `-9999`) values.

Project fields are added **only where the work needs them**:

| Field | Why |
|---|---|
| `layer_role` | `base` / `combining` / `overlay`; Regrid's `zoning_type` cannot separate base zoning from overlays |
| `code_status` | `current` / `retired` / `new`, from code reconciliation |
| `standards_source` | Per polygon: `regrid` or `research` (links to `standards_research.csv` by `municipality_id` + `zoning` + field) |
| `local_source_id` | Registry row in `zoning_sources.csv` used to verify the jurisdiction |
| `clipped` | Whether the polygon was trimmed to the jurisdiction boundary |
| `compiled_on`, `qa_status` | Build date and QA state |

New fields are added to this table, with a reason, before they are used.

### Jurisdiction boundaries (decided 2026-10-02)

- **Official boundaries:** MTC **`region_jurisdiction_clp`**
  ([FeatureServer/0](https://services3.arcgis.com/i2dkYWmb4wHvYPda/arcgis/rest/services/region_jurisdiction_clp/FeatureServer/0)),
  data edited 2025-07-01. It has 109 shoreline-clipped polygons: 101 cities and 8
  unincorporated county areas, matching the inventory exactly. Loaded as
  `zoning_inventory.jurisdiction_boundaries` with `municipality_id` (20
  source geometries repaired with `make_valid`). Its features tile with no
  overlaps, so city and unincorporated areas cannot double-count.
- **Clip** each zoning polygon to the boundary of the jurisdiction that
  published it; drop slivers under 0.05 acre.
- **What clipping removes** (measured on the June 2026 extract; to re-run on the baseline): 184,000 acres of
  Regrid zoning lies outside its own jurisdiction's boundary.
  - **93% (171,900 ac) is water or outside the region**, mostly county
    zoning drawn over the bay, ocean, and Suisun Marsh, and city zoning over
    shoreline water (e.g. Belvedere 80%, Tiburon 73% of their zoned area).
    This is removed.
  - **7% (12,100 ac) falls inside another jurisdiction**, e.g. San Ramon 832
    ac, Pittsburg 626, Napa 492, Pleasanton 434. Clipping resolves these by the
    official boundary. Pieces of 10 acres or more are listed for review
    against LAFCO annexation records (stale zoning on annexed land, or
    prezoning).
- **Streets and water stay unzoned** (decided). Unzoned area inside each
  boundary (median 9.5% of a jurisdiction) is classified as right-of-way,
  water, or true gap; only true gaps fail QA.

### Overlaps

| Kind | Rule |
|---|---|
| **Base vs overlay / combining zones** | Separate layers. Overlays (e.g. Oakland S-14, Milpitas transit tiers) go in an overlay table linked many-to-many to base districts. A curated `layer_role` per code (`base` / `combining` / `overlay`) in `zoning_codes.csv` replaces Regrid's `zoning_type = 'Overlay'`, which is unreliable (Berkeley's hillside base districts R-1H etc., 1,599 acres, are typed "Overlay"). |
| **Base vs base, same jurisdiction** | Not expected (none found in 5 POC cities). QA flags any; keep the most recently verified polygon or send to review. |
| **Between jurisdictions** | Removed by clipping each polygon to its own jurisdiction's official boundary (the boundaries themselves do not overlap). City-vs-unincorporated overlaps (Alameda County: Pleasanton 422 ac, Livermore 159 ac) are county zoning on annexed land and drop out. Clipped pieces of 10+ acres inside another jurisdiction go to review. |
| **Local vs Regrid** | Does not arise: geometry is always Regrid districts, replaced only whole-jurisdiction. |

## Source and input issues

Found while checking inputs (baseline `regrid_raw_202512`; June 2026
figures for comparison):

| Issue | Finding | Handling |
|---|---|---|
| **Parcel keys** | `regrid_raw_202512.parcels_union`: 2,328,626 parcels keyed by `ll_uuid`; 5,934 have no `zoning_id`; where the key matches, parcel `zoning` equals the district's (verified on June: 0 conflicts) | Join parcels to districts on `zoning_id` within one extract |
| **Unmatched parcel `zoning_id`s** ([DQ-001](data-quality-issues.md#dq-001-parcels-reference-zoning-districts-missing-from-regrids-zoning-layer)) | 98,487 parcels (4.2%) reference `zoning_id`s missing from the zoning layer: **Contra Costa 95,257 (24.6% of the county)**, Sonoma 2,912 (1.5%), Santa Clara 253. The per-county zoning tables have the same gap, so it is in Regrid's delivery. (June 2026 is worse: Contra Costa 39%, Marin 8.8%.) | Ask Regrid; spatial fallback until resolved; QA reports unmatched parcels per jurisdiction |
| **`zoning_id` is not stable across extracts** | Only 55% of June 2026 IDs exist in December 2025 (none reused for a different code) | Research and crosswalks keyed by `municipality_id` + `zoning`, never `zoning_id`; parcel joins always within one extract |
| **Regrid overlay typing** | `zoning_type = 'Overlay'` includes base districts (Berkeley hillside) | Curated `layer_role` |
| **Later extracts can lose data** | 8 standards that December has as real values are `-5555` in June (e.g. Monte Sereno minimum lot sizes) | Diff each new extract against the baseline before adopting it |

## QA/QC step

### Automated checks (`qa` command, per jurisdiction)

- **Geometry:** valid geometries; no base-zone self-overlap; no
  cross-jurisdiction overlap after clipping; spill outside boundary under 1%;
  unzoned area classified; local-source coverage at least 95%.
- **Codes:** every compiled polygon's code is in the compiled code list; every
  current code has a value or a research row for each priority standard; no
  open research rows on retired codes.
- **Value ranges:** height 10-500 ft; FAR 0-30; density 0-500 du/acre;
  density consistent with minimum lot size; `not_regulated` rows have no
  value; derived values state their basis in `conditions`.
- **Known Regrid issues:** no remaining `-9999` density in multifamily or
  mixed-use districts; codes absent from both the zoning code text and the
  local map are flagged (e.g. Windsor `HDR`).
- **Consistency:** large differences from MTC BASIS 2023 densities are
  flagged for review (BASIS is a comparator, not a source).
- **Vintage:** a local layer edited after the Regrid zoning date is flagged
  "Regrid likely stale"; a jurisdiction whose researched code is newer than
  its baseline districts is flagged "baseline older than code".

### Human review

- All drafted standards rows (as now), with priority for rows whose `notes`
  flag a judgment call.
- All substantive geometry differences of 1 acre or more, and all
  `replaced` / `new` code outcomes.
- A 10% spot check of each jurisdiction's `fixed` values against the code,
  to track drafting accuracy.
- **Jurisdiction sign-off** by a named reviewer moves it to `approved`.

## Status (2026-10-02)

| Item | State |
|---|---|
| Regrid profile (June 2026 extract) | Done: `docs/2026-10-02-zoning-profile.md` |
| Stream A: Berkeley pilot + batches 1-2 | 127 values researched across 20 jurisdictions; against the Dec 2025 baseline 114 drafted, 13 superseded; 4 open; none reviewed |
| Stream A: queue (Dec 2025 baseline) | 8,516 research rows from 6,626 zoning codes |
| Stream B: POC | 6 jurisdictions compared against the Dec 2025 baseline: Oakland, Marin high; Berkeley, Napa, San Jose medium; Milpitas low (75.7%, zoning code update). Against June 2026: 4 high, 2 medium |
| Database | `zoning_inventory` schema loaded with typed columns |
| Official boundaries | Loaded (`zoning_inventory.jurisdiction_boundaries`, MTC `region_jurisdiction_clp`, 2025-07-01) |
| Parcel key check | Done: `zoning_id` join valid; baseline 4.2% of parcels unmatched (mostly Contra Costa) |
| Compile and QA steps | Designed (this document); not built |

## Next steps

1. Decide the open questions below.
2. ~~Load official boundaries~~ (done: `zoning_inventory.jurisdiction_boundaries`).
3. Add `layer_role` and `code_status` to `zoning_codes.csv`.
4. Build `compile` and `qa` (`src/regional_zoning/`), and run them on the 20
   jurisdictions already researched, retroactively running source
   verification and comparison (steps 1-2) for those not yet compared.
5. Resume Stream A batches in the new order (source → compare → compile →
   research), starting with batch 3: Lafayette, Brentwood, Newark,
   Petaluma, Calistoga, Tiburon, Sausalito, San Anselmo, Hillsborough, Gilroy.
6. Stream B Phase 1: fill `zoning_sources.csv` for all 109 jurisdictions.

## Open decisions

| Decision | Recommendation |
|---|---|
| ~~Boundary source~~ | **Decided:** MTC `region_jurisdiction_clp` (2025-07-01) |
| ~~Master geometry~~ | **Decided:** Regrid zoning districts; parcels derived |
| ~~Schema~~ | **Decided:** Regrid zoning schema throughout; project fields only as needed (see Schema) |
| ~~Street and water areas~~ | **Decided:** leave unzoned, classified |
| ~~Replacement rule~~ | **Decided:** whole-jurisdiction only |
| ~~Research vintage~~ | **Decided:** current code; QA flag "baseline older than code"; reconcile at next baseline |
| Stale jurisdictions (e.g. Milpitas): wait for a newer Regrid extract, report to Regrid, or replace with the local layer conformed to Regrid's schema | Report to Regrid and flag in QA; local replacement only with staff approval |
| June 2026 build | Staff to confirm before it replaces the development baseline (checklist above) |
| Who approves `replaced` boundary changes | Staff, at jurisdiction sign-off; Claude drafts |
| Overlays/combining zones | Second pass, after base zoning |
| Missing zoning polygons for parcels (baseline: 98,487 parcels, mostly Contra Costa) | Report to Regrid; spatial fallback meanwhile |
| ~~Baseline extract~~ | **Decided:** `regrid_raw_202512` (matches `regrid_basis_202512`) |
| Regrid license terms for redistributing the compiled dataset | Confirm before publishing |
| Update cadence (Regrid extracts so far 2025-08, 2025-12, 2026-06; MTC boundaries 2025-07) | Rebuild per Regrid extract; check boundary layer each rebuild |
| Licensing / terms of local layers | Record per source in `zoning_sources.csv` before redistribution |

## Related documents

- `docs/2026-10-01-database-connection-notes.md`: database access
- `docs/2026-10-02-zoning-profile.md`: Regrid profile and placeholder codes
- `docs/2026-10-02-berkeley-pilot.md`, `docs/2026-10-02-batch1-small-jurisdictions.md`,
  `docs/2026-10-02-batch2-small-jurisdictions.md`: Stream A batches
- `docs/2026-10-02-local-zoning-source-inventory.md`: Stream B plan, research, POC
- `inventory/README.md`: inventory files and research conventions
- `docs/data-quality-issues.md`: data quality issue log (DQ-001: parcels referencing missing zoning districts)
