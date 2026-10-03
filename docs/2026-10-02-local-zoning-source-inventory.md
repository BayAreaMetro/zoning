# Local zoning source inventory: plan, research, and POC (2026-10-02)

Goal: a curated inventory of the **most current, publicly accessible zoning
map data published by each Bay Area jurisdiction**, used to (1) measure how
well Regrid's zoning matches current local zoning, and (2) feed updates into
the regional zoning dataset.

## Research findings

### Where Bay Area jurisdictions publish zoning maps

| Channel | How to find it | Examples (POC) |
|---|---|---|
| ArcGIS Online hosted layers | ArcGIS sharing REST search API (`title:zoning`, jurisdiction name), then filter by owner org | Oakland, City of Napa, Milpitas, Marin County |
| Jurisdiction-hosted ArcGIS Server | Browse the city's `/rest/services` directory | San Jose (`geo.sanjoseca.gov`) |
| Socrata open data portals | Socrata catalog API per domain | Berkeley (`data.cityofberkeley.info`) |
| PDF / image zoning maps only | City planning pages | Not in POC; expected for some small towns |

Search results are noisy. Name searches return other places with the same
name (Berkeley County SC, Brisbane AU) and non-zoning layers (flood or fire
"zones"). **Every candidate needs human confirmation**, recorded in the
registry (`verified_by`, `verified_date`). Prefer layers owned by the
jurisdiction's own organization over consultant or student copies.

### Existing regional compilations (comparators, not sources)

- **MTC/ABAG BASIS Draft Bay Area Zoning 2023** (public ArcGIS layer,
  179,248 polygons, data last edited 2023-10). It includes regional codes,
  densities, and links to zoning codes, but is explicitly draft and "users
  should always reference local data."
- **California Statewide Zoning (North/South)**, a state compilation from
  535 jurisdictions, collected 2021-2023 (some georeferenced from PDFs).
- Both are useful as fallbacks and comparators but are older than both Regrid
  (2025-2026 vintages) and the local layers.

### Practical issues found

- **Field choice matters.** Milpitas's `ZONE_CODE1` is a generalized category;
  the zone code is in `ZoningDescription`. The registry records the field.
- **Mislabeled coordinates.** Berkeley's Socrata GeoJSON carries UTM 10N
  coordinates labeled as WGS 84. The registry records a `source_crs`
  override.
- **Parcel-based vs district-based layers.** Napa and Milpitas publish
  zoning per parcel, while Regrid uses district polygons, so boundaries
  differ slightly along every district edge (sliver noise).
- **Regrid code formatting.** Regrid drops closing parentheses (`A(PD` vs
  `A(PD)`, `OS/(RCA` vs `OS (RCA)`) and changes separators (`/` vs `,`,
  `-AC` vs `:AC`). Comparisons must ignore punctuation.
- **Label differences** (San Jose `W` vs `WATER`) need a curated crosswalk.
- **Personal data.** Some parcel-based layers include situs addresses or
  APNs. Only the zone code field and geometry are downloaded.
- **Not reachable in POC:** DataSF (San Francisco) catalog API did not
  respond; to retry.

## POC results

Six jurisdictions, comparing `regrid_raw_202606.zoning_union` with each
jurisdiction's own layer (run `python -m regional_zoning.sources compare`).

> **Baseline update (2026-10-02):** the project baseline is now
> `regrid_raw_202512`. Re-run against it, agreement outside slivers is:
> Oakland 100% and Marin 100% (high); San Jose 97.5%, Berkeley 96.8%, Napa 93.5%
> (medium); Milpitas 75.7% (low). The older baseline predates Berkeley's
> middle-housing rezoning (R-1A to R-2, 155 ac), Napa's MU-CH/MU-CL districts,
> and most of Milpitas's zoning code update. Current results are in
> `inventory/zoning_source_comparison.csv`; the table below is the June run.

| Jurisdiction | Local layer last edited | Regrid zoning date | Regrid area covered | Exact code match | Match ignoring punctuation | Match excl. boundary slivers | Substantive disagreement | Rating |
|---|---|---|--:|--:|--:|--:|--:|---|
| Berkeley | 2026-08-12 | 2026-02-05 | 99.9% | 93.3% | 100.0% | 100.0% | 0 ac | high |
| Marin County Uninc. | 2026-06-03 | 2025-02-21 | 99.9% | 100.0% | 100.0% | 100.0% | 22 ac | high |
| Oakland | 2026-07-23 | 2025-08-28 | 100.0% | 92.1% | 99.7% | 100.0% | 3 ac | high |
| San Jose | n/a | 2026-02-04 | 99.5% | 71.9% | 99.1% | 99.3% | 664 ac | high |
| Napa | 2026-09-19 | 2026-02-09 | 99.3% | 46.9% | 98.1% | 97.5% | 159 ac | medium |
| Milpitas | 2026-08-13 | 2025-11-07 | 101.4% | 95.8% | 96.7% | 95.9% | 176 ac | medium |

Ratings: **high** >= 98% agreement (excluding pieces under 0.5 acre),
**medium** 90-98%, **low** < 90%, **coverage gap** if under 95% of Regrid's
area is covered by the local layer. "Substantive disagreement" is the area of
disagreeing pieces of at least 1 acre.

### What the disagreements are

- **Milpitas: real zoning changes.** HS to MHP (52 ac), MP to AD-BP (21 ac),
  MXD to MS-MU / XR-MU, C2 to XR-MU, TC1 to TC3. The local layer has codes
  Regrid lacks (GW-MU, LD-MU, MS-MU, XR-MU, AD-BP), consistent with
  Milpitas's zoning code update. **Regrid is out of date here.**
- **San Jose:** one 573-acre area is `A(PD)` in Regrid and `OS` locally, plus
  smaller A(PD) to IP/R-1-8 pieces. Needs a check of the city's rezoning
  record.
- **Napa:** 105 parcels (187 ac) have no zone code in the city layer, mostly
  parks that Regrid codes POS. That is a gap in the local layer, not a Regrid
  error. The remaining differences are sub-acre parcel-edge slivers.
- **Marin County:** ARP-20/ARP-10 vs ARP-60 on about 22 acres.
- **Oakland:** one 3-acre OS (AF) to RM-2 difference; otherwise slivers.
  Oakland's layer names its effective date and ordinance (2026-07-01,
  Ord. 13875).
- **Berkeley:** no substantive differences (Regrid already reflects the 2025-26
  middle-housing rezoning).

**Takeaway:** for these six, Regrid's district boundaries and codes agree
closely with local data (97.5-100% outside boundary slivers). The main risks
are (a) **stale vintages after rezonings** (Milpitas) and (b) **code
formatting**, which breaks naive joins. Local layers are not always better:
Napa's has gaps.

## Built in the POC

| Path | Purpose |
|---|---|
| `inventory/zoning_sources.csv` | Curated registry: one row per jurisdiction source (publisher, URL, zone field, CRS override, verification) |
| `inventory/zone_code_crosswalk.csv` | Curated Regrid-to-local code equivalences |
| `inventory/zoning_source_comparison.csv` | Comparison results per jurisdiction (regenerated) |
| `src/regional_zoning/sources.py` | `discover`, `fetch`, `compare` |
| `data_raw/local_zoning/` | Downloaded layers (gitignored) |

## Plan

### Phase 1: build the registry (all 109 jurisdictions)

1. Run `discover` for every jurisdiction and record candidates.
2. Add candidates from city/county ArcGIS Server directories and open data
   portals (Socrata, ArcGIS Hub), starting from the official code URLs already
   in `inventory/jurisdictions.csv`.
3. Human review: confirm the publisher is the jurisdiction, pick the base
   zoning layer (not overlays or drafts), and record the zone field. Mark
   PDF-only jurisdictions `platform = pdf` with the map URL and adoption date.
4. Record unincorporated county sources (county planning departments) for the
   8 county areas.

### Phase 2: compare and rate (automated)

1. Run `compare` for all `active` sources; review the top mismatches per
   jurisdiction and extend the crosswalk where differences are only labels.
2. Classify each jurisdiction: **high / medium / low / coverage gap /
   no GIS source**.
3. Publish the comparison table (and a summary page) for staff.

### Phase 3: feed updates into the regional dataset

1. For **medium/low** jurisdictions with substantive disagreement, review the
   changes against adoption records (ordinance numbers, effective dates).
2. Where local data is newer and verified, use the local zone code for
   affected areas, keeping Regrid's standards fields unless the code changed.
   New codes go into `inventory/zoning_codes.csv` and the `-5555` research
   queue.
3. Track provenance per polygon: `zone_source` (regrid / local), source URL,
   and date.

### Phase 4: keep it current

- Monthly: re-check each source's `editingInfo.dataLastEditDate` (cheap) and
  re-run `compare` only for sources that changed or for new Regrid extracts.
- Flag jurisdictions whose local layer changed since the last Regrid vintage
  as **likely stale in Regrid**.
- Review sources not verified in 12 months.

### Effort estimate

- Discovery and verification: roughly 10-15 minutes per jurisdiction, so
  about 3-4 staff days for all 109 (Claude can draft candidates; staff
  confirm).
- Comparison runs are automated (minutes per jurisdiction).

### Open decisions

- **Authority rule:** when local and Regrid disagree and local is newer, does
  the regional dataset adopt local codes automatically, or only after
  review? (Recommended: after review, for now.)
- **Licensing/terms:** most layers are public, but terms vary; record them in
  the registry before redistribution.
- **Overlays:** include combining/overlay zones (Oakland S-14, Milpitas
  overlays) in a second pass.
