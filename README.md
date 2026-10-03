# Bay Area Regional Zoning Dataset

Develop a consistent, region-wide zoning dataset for the nine-county San Francisco Bay Area by combining:

- **Vendor datasets**: commercially or publicly distributed zoning compilations
- **Local agency zoning data**: zoning maps and ordinances published by cities and counties, inventoried in this project

The project builds a compiled regional zoning layer from Regrid standardized zoning (development baseline `regrid_raw_202512`), clipped to MTC's official jurisdiction boundaries, with researched development standards (resolving Regrid's `-5555` / `-9999` placeholders), overlay districts kept in separate tables, a curated inventory of each jurisdiction's own published zoning layer for comparison, and automated QA.

> This repository continues the work begun on the `regional-zoning` branch of [BayAreaMetro/zoning](https://github.com/BayAreaMetro/zoning), whose `master` branch (the legacy 2010 parcel-zoning pipeline) is not part of this project. Commit history from that branch is preserved here.

## Goals

1. **Inventory** the zoning data available for each Bay Area jurisdiction: source, format, vintage, update cadence, and license/terms of use.
2. **Evaluate** vendor datasets against local agency data for coverage, currency, and accuracy.
3. **Standardize** local zoning districts into a common regional schema (permitted uses, density, intensity, height, etc.).
4. **Produce** a documented regional zoning dataset with provenance tracked for every feature.

See **[docs/project-workplan.md](docs/project-workplan.md)** for how the work is organized: two work streams (standards research and the local zoning source inventory), the per-jurisdiction pipeline (verify source → compare → compile → research → QA/QC → publish), and the rules for geometry, jurisdiction boundaries, and overlaps.

## Setup

Requires Python 3.10–3.13 (3.12 recommended; geospatial packages may not have prebuilt wheels for 3.14 yet) and access to the project Postgres/PostGIS database, where the source data (starting with Regrid) is staged.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

cp .env.example .env   # then fill in the database connection values
python -m regional_zoning.db   # verify the connection
```

If `pip install` tries to build `pyproj` or another geospatial package from source (common on older macOS versions), rerun it with `--prefer-binary` so pip picks a version with a prebuilt wheel.

## Repository layout

| Path | Contents |
|---|---|
| `src/regional_zoning/` | Python package (`db.py`: database connection from `.env`; `profile_zoning.py`: Regrid zoning profile; `inventory.py`: jurisdiction inventory and research queue; `sources.py`: local zoning source discovery and comparison) |
| `inventory/` | Jurisdiction inventory and research queue for Regrid `-5555` values (see `inventory/README.md`) |
| `docs/` | Methodology, schema definitions, and decision notes |

Raw and intermediate data are not committed (see `.gitignore`).
