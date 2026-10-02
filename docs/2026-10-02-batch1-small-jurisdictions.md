# Batch 1: small jurisdictions (2026-10-02)

The 10 jurisdictions with the fewest priority-1 queue rows: Cotati, Dixon,
Larkspur, Los Altos Hills, Oakley, Rio Vista, Rohnert Park, Suisun City,
Windsor, Woodside. 21 queue rows, plus a `-9999` density check for
multifamily and mixed-use districts (per the Berkeley pilot). All values are
**drafted** by Claude and need staff review.

## Results

| | Rows |
|---|--:|
| `-5555` values drafted | 19 of 21 |
| Open (see below) | 2 |
| `-9999` values found to be wrong (added as corrections) | 8 |

**Open items**
- **Suisun City RMU FAR:** no official online code found. Regrid links to a
  vendor, and the only text found (GoCodebook, third-party) lacks the standards
  table. Needs the adopted Title 18 from the city.
- **Windsor HDR height:** HDR is a General Plan designation, not a zone in the
  current code (the CR zone implements it, at 4 stories). Regrid's `HDR`
  polygons likely carry an outdated zone code; check the city zoning map.

## Findings

- **`-9999` density is unreliable for multifamily districts.** In all 7
  districts checked, Regrid had `-9999` but the code regulates density,
  usually as lot area per unit rather than du/acre:
  Larkspur R-2 (10.9) and R-3 (21.8); Rio Vista R-1 (7.3), R-2 (14.5), R-3
  (29.0), R-4 (29.0); Oakley M-H (7 sites/acre). Rio Vista R-3's minimum lot
  (6,000 sq ft) was also `-9999`. This is consistent with Berkeley: **`-9999`
  for density should be checked everywhere, not spot-checked.**
- **Not checked:** Larkspur MHP and RMP, Oakley A-3, and single-family districts (one home per lot), whose density is implied by minimum lot size;
  check these in a later pass.
- **`-5555` usually meant a standard that isn't a single number:**
  - floor area set by a formula or a percentage of lot area rather than a ratio
    (Los Altos Hills, Woodside), recorded as an equivalent FAR with the
    derivation in `notes`;
  - minimum lot size set by a zoning-map suffix (Cotati RR-1.0/RR-1.5,
    RVL-0.5/RVL-0.66) that Regrid's codes drop;
  - height in stories only (Windsor CR: 4 stories);
  - values that depend on project type (Dixon CMX FAR 2.0 single use / 2.4
    multi-use; Rohnert Park DTM-U residential only in mixed-use buildings).

## Source and access notes

| Jurisdiction | Official code | Note |
|---|---|---|
| Larkspur | larkspur.municipal.codes | Cloudflare bot protection; read one page at a time |
| Rio Vista, Los Altos Hills | ecode360 | Rio Vista's summarized zoning schedule (17.06.010) has most standards in one table |
| Oakley, Cotati | ecode360 | **Regrid links are out of date**: both moved from Code Publishing to ecode360 |
| Dixon | ecode360 | Zoning code fully rewritten, effective 2024-06-06 |
| Woodside, Rohnert Park, Windsor | Municode | Pages load slowly; one table per chapter |
| Suisun City | not found | Only a third-party copy (GoCodebook) |

Official code URLs are recorded in `inventory/jurisdictions.csv`.

## Review checklist

Same as the Berkeley pilot (`2026-10-02-berkeley-pilot.md`). Judgment calls
flagged in `notes`:
- derived FAR equivalents (Los Altos Hills, Woodside R-1);
- derived densities from lot area per unit (all 8 corrections);
- map-suffix lot sizes (Cotati), recorded at the smaller size;
- Windsor CR height (stories only, no value in feet).
