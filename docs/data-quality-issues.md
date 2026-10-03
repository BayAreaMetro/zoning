# Data quality issues

Log of data quality problems found in project inputs. Each issue records the
evidence, how to reproduce it, its impact, and how the project handles it
until it is resolved. Add new issues at the end with the next ID.

| ID | Title | Source | Severity | Status |
|---|---|---|---|---|
| DQ-001 | Parcels reference zoning districts missing from Regrid's zoning layer | Regrid (`parcels_union` / `zoning_union`) | High | Open: report to Regrid ([#22](https://github.com/BayAreaMetro/zoning/issues/22)) |
| DQ-002 | Redwood City zoning covers about 39% of the city | Regrid (`zoning_union`, Dec 2025) | Medium | Open |

---

## DQ-001: Parcels reference zoning districts missing from Regrid's zoning layer

- **Found:** 2026-10-02
- **Source:** Regrid extracts `regrid_raw_202512` (development baseline) and `regrid_raw_202606`
- **Severity:** High. A quarter of Contra Costa parcels cannot be joined to their zoning district.
- **Status:** Open. Report to Regrid; handled with a spatial fallback.
- **GitHub issue:** [BayAreaMetro/zoning#22](https://github.com/BayAreaMetro/zoning/issues/22)

### Summary

Regrid parcels (`parcels_union`) link to their base zoning district by
`zoning_id`. A large share of parcels carry a `zoning_id` that does not exist
in the zoning layer (`zoning_union`) of the same extract. The gap is
concentrated in **Contra Costa County** and gets worse in the June 2026
extract.

### Join key

`parcels_union.zoning_id = zoning_union.zoning_id`, a left join **within the
same schema** (December parcels to December zoning, June to June). A parcel
is **unmatched** when its `zoning_id` is not null but no `zoning_union` row
has that ID.

### Evidence

| | Dec 2025 (`regrid_raw_202512`) | Jun 2026 (`regrid_raw_202606`) |
|---|--:|--:|
| Parcels | 2,328,626 | 2,339,687 |
| Distinct `ll_uuid` (parcel key is unique) | 2,328,626 | 2,339,687 |
| Parcels with no `zoning_id` | 5,934 | 6,443 |
| **Parcels with an unmatched `zoning_id`** | **98,487 (4.2%)** | **160,994 (6.9%)** |
| Distinct missing `zoning_id`s | 2,073 | 5,000 |
| Matched parcels whose `zoning` differs from the district's | 0 | 0 |

Unmatched parcels by county:

| County | Dec 2025 | Jun 2026 |
|---|--:|--:|
| Alameda (06001) | 15 | 0 |
| **Contra Costa (06013)** | **95,257 (24.6%)** | **152,501 (39.3%)** |
| Marin (06041) | 30 | 8,442 (8.8%) |
| Napa (06055) | 0 | 17 |
| San Francisco (06075) | 0 | 0 |
| San Mateo (06081) | 0 | 0 |
| Santa Clara (06085) | 253 | 28 |
| Solano (06095) | 20 | 5 |
| Sonoma (06097) | 2,912 (1.5%) | 1 |

Contra Costa unmatched parcels by Regrid `city` (census county subdivision),
December 2025: central Contra Costa 34,810; Antioch-Pittsburg 23,858; west
Contra Costa 15,935; Tassajara 14,422; east Contra Costa 6,232. In June 2026
Marin's unmatched parcels are almost all in Ross Valley (8,438).

### The gap is in Regrid's delivery, not our processing

- The same join on Regrid's per-county tables (`ca_<county>.zoning_id` vs
  `ca_<county>_zoning.zoning_id`) shows the same missing IDs, so the union
  step did not drop them. June 2026: Contra Costa 4,269 missing IDs, Marin 724.
- `zoning_union` row counts equal the per-county zoning table counts in each
  extract.
- The June 2026 missing IDs do not appear in the August 2025 or December 2025
  zoning tables either.
- Exactly 5,000 distinct missing IDs in June 2026 may indicate a truncated
  export.

### Reproduce

```sql
-- Unmatched parcels by county (swap the schema for another extract)
select p.geoid,
       count(*)                                                    as parcels,
       count(*) filter (where p.zoning_id is null)                 as no_id,
       count(*) filter (where p.zoning_id is not null
                          and z.zoning_id is null)                 as unmatched
from regrid_raw_202512.parcels_union p
left join regrid_raw_202512.zoning_union z on p.zoning_id = z.zoning_id
group by rollup (p.geoid)
order by p.geoid;

-- Same check on a Regrid per-county table
select count(distinct p.zoning_id)
from regrid_raw_202606.ca_contra_costa p
where p.zoning_id is not null
  and not exists (select 1 from regrid_raw_202606.ca_contra_costa_zoning z
                  where z.zoning_id = p.zoning_id);
```

### Impact

- Parcel-level zoning and capacity cannot be derived by key for about 95,000
  Contra Costa parcels (December baseline), or about 153,000 in June 2026.
- If the zoning polygons themselves are missing (not just the IDs), parts of
  Contra Costa may have no district geometry in the zoning layer. Not yet
  checked spatially.
- Adopting the June 2026 extract as-is would make the problem worse (Contra
  Costa 39%, Marin 8.8%).

### Handling until resolved

- Parcels join to districts by `zoning_id`; unmatched parcels fall back to a
  spatial assignment (largest overlap with a baseline district), flagged in QA.
- QA reports unmatched parcels per jurisdiction.
- This issue is part of the checklist for confirming the June 2026 build
  (`docs/project-workplan.md`, "Adopting the June 2026 build").

### Update 2026-10-02: whole cities have stale parcel links, not missing polygons

The QA step locates each unmatched parcel by position (point on surface within
the official boundaries). In six jurisdictions **every parcel** is unmatched
(December 2025 baseline):

| Jurisdiction | Unmatched parcels | Regrid zoning date (Dec) | Zoning polygons present |
|---|--:|---|--:|
| Antioch | 35,558 (100%) | 2025-10-13 | 231 (18,480 ac) |
| San Ramon | 26,455 (100%) | 2025-10-14 | 352 |
| Danville | 16,875 (100%) | 2025-10-14 | 920 |
| El Cerrito | 8,883 (100%) | 2025-10-14 | 67 |
| San Pablo | 7,031 (100%) | 2025-10-09 | 130 |
| Sebastopol | 2,932 (100%) | 2025-10-13 | 262 |

The zoning polygons exist and cover these cities, but the parcels'
`zoning_id`s do not appear in the December or June zoning layers. All six
had their Regrid zoning reissued in October 2025, so the likely cause is
**parcel links not refreshed after zoning was reissued with new IDs**. For
these cities the spatial fallback assigns parcels correctly. Six more
jurisdictions have 1-3% unmatched (Redwood City, Benicia, Albany, Monte
Sereno, Cloverdale, Cotati).

### Asks for Regrid

1. Confirm whether Contra Costa (and, for June 2026, Marin) zoning polygons are
   missing from the delivery, or whether parcels carry stale `zoning_id`s.
2. Re-deliver the missing zoning features or corrected parcel `zoning_id`s.
3. Confirm whether the June 2026 zoning export was truncated (5,000 distinct
   missing IDs).
4. Confirm whether parcel `zoning_id`s are refreshed when a jurisdiction's
   zoning is reissued (Antioch, San Ramon, Danville, El Cerrito, San Pablo,
   Sebastopol: 100% unmatched since October 2025).

### Next steps

- [ ] Report to Regrid (owner: staff).
- [x] Spatial check: for the six 100%-unmatched cities, the zoning polygons
      are present; the parcel links are stale (see update above).
- [ ] Re-check after Regrid's response and before adopting `regrid_raw_202606`.

---

## DQ-002: Redwood City zoning covers about 39% of the city

- **Found:** 2026-10-02 (QA step, `high_unzoned_share`)
- **Source:** Regrid `regrid_raw_202512.zoning_union` (Redwood City zoning date 2024-05-31)
- **Severity:** Medium
- **Status:** Open

### Summary

After clipping to the official (shoreline-clipped) boundary, **61% of Redwood
City has no zoning** in the December 2025 baseline: 1,193 districts cover
5,504 of the city's 14,104 acres. Other cities typically have 5-20% unzoned
(streets and water). In the June 2026 extract Redwood City's zoning covers far
more area (about 20,900 acres, much of it bay water outside the shoreline), so
the December delivery appears incomplete for Redwood City.

### Handling

- Kept as delivered; QA flags it (`high_unzoned_share`).
- Compare with Redwood City's own zoning map (Stream B) and with the June 2026
  extract when its build is confirmed.

### Next steps

- [ ] Add Redwood City's local zoning layer to `inventory/zoning_sources.csv` and compare.
- [ ] Check whether the June 2026 extract fills the gap.
- [ ] Report to Regrid if the gap is confirmed.
