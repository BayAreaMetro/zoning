"""Postgres connection helpers.

Connection parameters are read from environment variables, loaded from a
`.env` file in the repository root if present (see `.env.example`).
"""

import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import URL, Engine, create_engine, text

REPO_ROOT = Path(__file__).resolve().parents[2]

load_dotenv(REPO_ROOT / ".env")

REQUIRED_VARS = ("PGHOST", "PGDATABASE", "PGUSER", "PGPASSWORD")


def _connection_url() -> URL:
    missing = [v for v in REQUIRED_VARS if not os.getenv(v)]
    if missing:
        raise RuntimeError(
            f"Missing database settings: {', '.join(missing)}. "
            f"Copy .env.example to {REPO_ROOT / '.env'} and fill it in."
        )
    return URL.create(
        "postgresql+psycopg",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ["PGHOST"],
        port=int(os.getenv("PGPORT", "5432")),
        database=os.environ["PGDATABASE"],
        query={"sslmode": os.getenv("PGSSLMODE", "prefer")},
    )


@lru_cache(maxsize=1)
def get_engine() -> Engine:
    """Return a shared SQLAlchemy engine for the project database."""
    return create_engine(_connection_url(), pool_pre_ping=True)


def check_connection() -> str:
    """Connect and return the server's Postgres and PostGIS versions."""
    with get_engine().connect() as conn:
        pg = conn.execute(text("SELECT version()")).scalar_one()
        postgis = conn.execute(
            text("SELECT extversion FROM pg_extension WHERE extname = 'postgis'")
        ).scalar_one_or_none()
    return f"{pg}\nPostGIS: {postgis or 'not installed'}"


if __name__ == "__main__":
    print(check_connection())
