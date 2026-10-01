# Bay Area Regional Zoning Dataset

Develop a consistent, region-wide zoning dataset for the nine-county San Francisco Bay Area by combining:

- **Vendor datasets**: commercially or publicly distributed zoning compilations
- **Local agency zoning data**: zoning maps and ordinances published by cities and counties, inventoried in this project

> This branch is a fresh start and does not share history with the legacy 2010 parcel-zoning pipeline on `master`.

## Goals

1. **Inventory** the zoning data available for each Bay Area jurisdiction: source, format, vintage, update cadence, and license/terms of use.
2. **Evaluate** vendor datasets against local agency data for coverage, currency, and accuracy.
3. **Standardize** local zoning districts into a common regional schema (permitted uses, density, intensity, height, etc.).
4. **Produce** a documented regional zoning dataset with provenance tracked for every feature.

## Repository layout

| Path | Contents |
|---|---|
| `inventory/` | Inventory of jurisdictional and vendor zoning sources |
| `docs/` | Methodology, schema definitions, and decision notes |

Raw and intermediate data are not committed (see `.gitignore`).
