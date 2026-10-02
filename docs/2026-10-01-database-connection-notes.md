# Database connection test — session notes (2026-10-01)

Summary of a Claude Code cloud session that tried to verify the project's
Postgres/PostGIS connection (`python -m regional_zoning.db`).

## What was tried

1. **Looked for a report to review.** None was attached and none exists in the
   repo yet (`docs/` and `inventory/` were empty). Still pending: share the
   report so it can be reviewed against the project goals and turned into a plan.
2. **Tested the database connection from the cloud session.**
   - Connection settings (`PGHOST`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`,
     `PGSSLMODE=require`) were present in the cloud environment.
   - The package and dependencies installed successfully (`pip install -e .`).
   - A TCP connection to the RDS host on port 5432 **timed out**, so
     `python -m regional_zoning.db` hung until it was killed. Retried once with the same result.

## Why it fails

Anthropic-hosted cloud sessions send all outbound traffic through an
HTTP/HTTPS proxy, and the network settings only allow traffic by domain name. Raw Postgres traffic
(port 5432) cannot leave the session, even with **Full** network access.

- There is **no published list of outbound IPs** for cloud sessions, and each
  session runs on a new short-lived machine, so an AWS security-group allowlist is not a fix.
- The database itself is fine: the same credentials connect from a local
  device using TablePlus.

## Options

| Option | How | Notes |
|---|---|---|
| **Remote Control / local session** (recommended now) | Run Claude Code on a computer that already reaches the database, using the Desktop app (**Local**) or `claude remote-control` in the repo folder | No AWS changes. Needs a laptop/desktop, not a phone or tablet. |
| **Self-hosted environment** | Org admins run cloud-session machines on MTC infrastructure (e.g. the same AWS account as the RDS instance) | Long-term answer for cloud sessions; allow traffic with a normal security-group rule. |
| **Web-based route to the data** | Internal API in front of the database, or exports to S3/BigQuery | More moving parts; only if wanted for other reasons. |

## Running the test locally

```bash
git clone https://github.com/bayareametro/zoning.git && cd zoning
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env   # fill in the same values TablePlus uses
python -m regional_zoning.db   # prints Postgres and PostGIS versions
```

## Next steps

- [x] Run the connection test from a local session.
- [x] Confirm the PostGIS version and list the staged Regrid tables.
- [ ] Share the report for review and planning.

## Local session results

The connection test passed from a local Claude Code session on an Intel iMac
(macOS 13): **PostgreSQL 17.9, PostGIS 3.5.1**.

Local Python setup notes:

- Python 3.14 could not install the geospatial dependencies; the project venv
  now uses Python 3.12 (Homebrew `python@3.12`).
- pyproj 3.8 only publishes an Intel Mac wheel for macOS 15+, so pip tried to
  build it from source and failed. `pyproject.toml` now pins `pyproj<3.8`
  (3.7.2 has a macOS 13 wheel); `pip install --prefer-binary` also works.

Staged Regrid schemas (table names only; contents not yet profiled):

| Schema | Contents |
|---|---|
| `regrid_raw_202508`, `regrid_raw_202512`, `regrid_raw_202606` | Raw Regrid extracts: parcels, buildings, building joins, and zoning for all 9 counties, plus region-wide union tables (e.g. `zoning_union`) |
| `regrid_202407` | Older extract: parcel, zoning, and building source tables |
| `regrid_dev_v25` | Per-county working tables, `bayarea_zoning_merged`, `bayarea_parcels_unified`, jurisdiction lookup/boundaries |
| `regrid_basis_202512`, `regrid_dev_202512` | Parcel tables split by topic (zoning, land use, valuation, ownership, etc.), housing element sites, annual progress reports |
| `regrid_anderson_v25` | Land-use classification pipeline outputs, run logs, and audits |
| `regrid_themes_v25` | Per-county themed tables and a column dictionary |

Likely starting points for zoning work: `regrid_raw_202606.zoning_union` and
`regrid_dev_v25.bayarea_zoning_merged`. Ownership and address tables likely
contain owner PII and should be excluded from analysis outputs.

- [x] Profile the zoning tables (coverage by jurisdiction, district codes, fields).
      See `2026-10-02-zoning-profile.md`.

References: https://code.claude.com/docs/en/claude-code-on-the-web,
https://code.claude.com/docs/en/cloud-environments
