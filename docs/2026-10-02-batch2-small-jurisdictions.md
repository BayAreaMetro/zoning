# Batch 2: small jurisdictions (2026-10-02)

The next 10 jurisdictions by queue size: American Canyon, Atherton,
Emeryville, Monte Sereno, Napa, Pacifica, Piedmont, Solano County
(unincorporated), Sonoma, Yountville. 54 priority-1 queue rows, plus a `-9999`
density check for multifamily and mixed-use districts. All values are
**drafted** by Claude and need staff review.

## Results

| | Rows |
|---|--:|
| `-5555` values drafted | 52 of 54 |
| Open | 2 (Solano County I-AS lot area, P height) |
| `-9999` values found to be wrong (added as corrections) | 19 |
| `-9999` density confirmed correct | 1 (Yountville RSC) |

## Findings

### Density is often regulated outside the zoning table

A `-9999` density usually meant the zoning code regulates density
somewhere Regrid did not capture:

| Where density lives | Jurisdictions | Corrections |
|---|---|--:|
| Lot area per unit in the district text (converted to du/acre) | Pacifica R-2/R-3/R-3.1/R-3-G (15.0-21.0); Solano County R-TC-D-4/D-6 (21.8/14.5) | 6 |
| A district purpose statement | American Canyon RM (5-12 du/acre) | 1 |
| **General Plan density map or ranges**, by reference | Emeryville (all 6 residential/mixed zones; 35-85 base, up to 170 with bonus); Napa (RM, RT-4, RT-5, DMU, MU-G, MU-T) | 12 |

The last group cannot be resolved from the zoning code: **Emeryville and Napa
need General Plan layers** (Emeryville's FAR, height, and density maps; Napa's
GP 2040 density ranges) to assign parcel-level values. Those corrections are
recorded with a blank `value` and the rule in `conditions`.

### What `-5555` meant

- **Standards that vary by sub-area** within one zone: Sonoma sets height and
  FAR per planning area (13 areas; MX FAR 0.60-1.20); Napa MU-T height by
  area (30 ft edges, 50 ft interior); Piedmont Zone D by subarea.
- **FAR by lot-size tier or formula**: Atherton (18%, formula under 1 acre),
  Piedmont Zones A/E (55%/50%/45%), Yountville RS/RM (by unit type).
- **Height measured at the setback line and stepping up**: Monte Sereno
  (21 ft at setback, 30 ft max).
- **No minimum lot area** (`not_regulated`): Emeryville (all but RM),
  Piedmont Zone D.
- **Lot size by slope formula or new parcels only**: Monte Sereno, American
  Canyon (20,000 sq ft applies only to new parcels in RM/RH).

### Regrid codes that do not match the current zoning code

- **Napa MU-CH, MU-CL, MU-R**: not zones in the current zoning code (likely
  General Plan 2040 designations), like Windsor `HDR` in batch 1.
- Name differences only: Yountville `MR` = RM; Solano County `RTC-*` =
  `R-TC-*`.

### Stale vintages

- **Pacifica**: Regrid data 2024-05-30; the code has since been amended
  (Ord. 902-C.S., 2025, and new higher-density districts in Article 54).
- **Piedmont**: Regrid links a 2025-11-06 PDF that returns 404; the PDF used
  is amended through Ord. 777 N.S. (01/2025), so it may predate later changes.

## Not checked

- Napa Pipe master plan districts (3), American Canyon TC/TC-PARK (likely the
  Town Center Specific Plan), Solano County R-TC-MF/R-TC-MU density, Napa RO.
- Sonoma planning areas 19.24-19.30 and 19.36 (MX range may widen).

## Sources

| Jurisdiction | Official code |
|---|---|
| Atherton, Sonoma | municipal.codes |
| Emeryville, Napa, Yountville | ecode360 (Emeryville moved from Code Publishing) |
| Monte Sereno, Pacifica | Municode |
| American Canyon | law.cityofamericancanyon.org |
| Piedmont | City Code Chapter 17 PDF (piedmont.ca.gov) |
| Solano County | Code Publishing (Regrid links to a vendor) |

## Review checklist

Same as earlier batches. Judgment calls flagged in `notes`: blank-value
corrections that defer to the General Plan; Sonoma MX FAR recorded as the
highest planning-area value; Piedmont Zone D FAR (non-residential only).
