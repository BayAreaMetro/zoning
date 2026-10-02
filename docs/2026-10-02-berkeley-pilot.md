# Berkeley pilot: resolving Regrid `-5555` values (2026-10-02)

Pilot of the research workflow in `inventory/README.md`, on Berkeley's 25
priority-1 queue rows (Residential and Mixed districts, housing-capacity
standards). All values are **drafted** by Claude from the Berkeley Municipal
Code (BMC Title 23, current through Ord. 8007-NS, 2026) and **need staff
review** before they are marked `approved`.

## Results

| | Rows |
|---|--:|
| `-5555` values resolved to a number | 20 |
| `-5555` values that are actually "no maximum / no minimum" (`not_regulated`) | 5 |
| `-9999` values found to be wrong (added as corrections) | 4 |
| Regrid real values checked against the code | 9 of 9 matched |

### What `-5555` meant in practice

- **Height (13 rows):** almost always a clear base limit plus a higher limit with
  a discretionary permit (e.g. R-4: 35 ft by right, 65 ft with a Use Permit) or
  a hillside overlay variant. Recorded the by-right limit in `value` and the
  rest in `conditions`.
- **Max density in R-3, R-S, R-SMU, R-BMU (4 rows):** the code sets a
  *minimum* density and explicitly **no maximum**. Correct answer is
  `not_regulated`, not a number.
- **Plan-area splits:** R-3 has different standards inside and outside the
  Southside Plan area. Recorded the citywide case and flagged it for review;
  a parcel-level layer will need the plan boundary.

### Regrid `-9999` errors

Regrid has max density as `-9999` ("not applicable") in **R-1, R-2, R-2A, and
MU-R**, but the code sets a maximum of **70 du/acre** in each (adopted with
Berkeley's 2025 middle-housing amendments). These four districts cover 824 of
Berkeley's 1,776 zoning polygons, so this matters for capacity estimates.
Corrections were added to the queue as extra rows (`regrid_value = -9999`).

**Implication for scale-up:** `-9999` cannot be trusted for density in
jurisdictions that recently amended their codes. Add a `-9999` density check
for Residential and Mixed districts to each jurisdiction's research.

### Capacity caveats captured in `notes`

- **ES-R:** no new dwelling units may be approved until a Panoramic Hill
  Specific Plan is adopted (BMC 23.202.070.E), so effective capacity is zero
  regardless of the height and FAR limits.
- **MU-R FAR:** the 1.5 FAR applies only to non-residential floor area in
  live/work buildings; residential floor area has no FAR limit.

## Process notes

- **Effort:** about 12 page reads for 29 values, since one district section
  answers all standards for that district. Research should be organized by
  district, not by queue row.
- **Access:** berkeley.municipal.codes blocks automated fetching (HTTP 403);
  pages were read through a browser. Other code hosts may need the same.
- **Tables:** some code tables use merged cells (e.g. C-DMU heights), which
  flatten ambiguously as text; read the table structure, not just the text.
- **Not yet covered:** density and FAR for C-DMU and MRD (Regrid `-9999`),
  bonus programs (State Density Bonus is noted only as a convention), and the
  46 priority-3 Berkeley rows.

## Review checklist

For each `drafted` Berkeley row in `inventory/standards_research.csv`:

1. Open `source_url` and confirm `value` and `conditions` against
   `source_section`.
2. Decide the two flagged cases: R-3 FAR and MU-R FAR (see `notes`).
3. Set `status` to `approved` or `needs_revision`, and fill `reviewer` and
   `reviewed_date`.
