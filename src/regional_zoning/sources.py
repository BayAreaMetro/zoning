"""Local jurisdiction zoning source inventory and comparison with Regrid.

The curated registry `inventory/zoning_sources.csv` lists, per jurisdiction,
the most current publicly accessible zoning map data published by the
jurisdiction itself. This module:

- `discover`: searches ArcGIS Online for candidate zoning layers (to help
  curators fill the registry; results need human review).
- `fetch`: downloads a registered layer (zone code field + geometry only) to
  `data_raw/local_zoning/<municipality_id>.parquet` (gitignored).
- `compare`: overlays the local layer with Regrid zoning for the same
  jurisdiction and reports coverage and zone-code agreement.

Usage:
    python -m regional_zoning.sources discover "City Name"
    python -m regional_zoning.sources compare [municipality_id ...]
"""

import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import date, datetime, timezone

import geopandas as gpd
import pandas as pd

from regional_zoning.db import REPO_ROOT, get_engine
from regional_zoning.inventory import SOURCE_TABLE

REGISTRY = REPO_ROOT / "inventory" / "zoning_sources.csv"
RESULTS = REPO_ROOT / "inventory" / "zoning_source_comparison.csv"
CROSSWALK = REPO_ROOT / "inventory" / "zone_code_crosswalk.csv"
CACHE_DIR = REPO_ROOT / "data_raw" / "local_zoning"
AREA_CRS = "EPSG:3310"  # California Albers, for area calculations
USER_AGENT = "regional-zoning-inventory (MTC/ABAG research)"
SQ_M_PER_ACRE = 4046.8564
SLIVER_ACRES = 0.5  # overlay pieces smaller than this are treated as boundary noise
SUBSTANTIVE_ACRES = 1.0  # disagreeing pieces at least this large are listed for review


def _get_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.load(resp)


def _quote_url(url: str) -> str:
    """Escape spaces etc. in a service URL path, leaving the scheme/host intact."""
    parts = urllib.parse.urlsplit(url)
    return urllib.parse.urlunsplit(parts._replace(path=urllib.parse.quote(parts.path)))


# --- discovery -------------------------------------------------------------

def discover(name: str, limit: int = 25) -> pd.DataFrame:
    """ArcGIS Online items titled 'zoning' that mention the jurisdiction name."""
    q = urllib.parse.urlencode({
        "f": "json", "num": limit, "sortField": "modified", "sortOrder": "desc",
        "q": f'title:zoning AND "{name}" AND (type:"Feature Service" OR type:"Map Service")',
    })
    d = _get_json("https://www.arcgis.com/sharing/rest/search?" + q)
    return pd.DataFrame([{
        "title": r["title"], "owner": r["owner"], "type": r["type"],
        "modified": date.fromtimestamp(r["modified"] / 1000), "url": r.get("url"),
    } for r in d["results"]])


# --- fetching --------------------------------------------------------------

def layer_metadata(src: pd.Series) -> dict:
    """Last data edit date reported by the service, where available."""
    if src.platform != "arcgis":
        meta = _get_json(f"https://{src.socrata_domain}/api/views/{src.dataset_id}.json")
        ts = meta.get("rowsUpdatedAt")
    else:
        meta = _get_json(_quote_url(src.service_url) + "?f=json")
        info = meta.get("editingInfo") or {}
        ts = info.get("dataLastEditDate") or info.get("lastEditDate")
        ts = ts / 1000 if ts else None
    return {"source_last_edit": datetime.fromtimestamp(ts, timezone.utc).date() if ts else None}


def _fetch_arcgis(url: str, field: str) -> gpd.GeoDataFrame:
    url = _quote_url(url)
    page = _get_json(url + "?f=json").get("maxRecordCount") or 1000
    frames, offset = [], 0
    while True:
        q = urllib.parse.urlencode({
            "where": "1=1", "outFields": field, "returnGeometry": "true", "outSR": 4326,
            "f": "geojson", "resultOffset": offset, "resultRecordCount": page,
        })
        d = _get_json(f"{url}/query?{q}")
        feats = d.get("features", [])
        if feats:
            frames.append(gpd.GeoDataFrame.from_features(feats, crs="EPSG:4326"))
        if len(feats) < page and not d.get("properties", {}).get("exceededTransferLimit"):
            break
        offset += len(feats)
        time.sleep(0.5)
    return pd.concat(frames, ignore_index=True)


def _fetch_socrata(domain: str, dataset_id: str, field: str) -> gpd.GeoDataFrame:
    q = urllib.parse.urlencode({"$select": f"{field},the_geom", "$limit": 50000})
    d = _get_json(f"https://{domain}/resource/{dataset_id}.geojson?{q}")
    return gpd.GeoDataFrame.from_features(d["features"], crs="EPSG:4326")


def fetch(src: pd.Series, refresh: bool = False) -> gpd.GeoDataFrame:
    path = CACHE_DIR / f"{src.municipality_id}.parquet"
    if path.exists() and not refresh:
        return gpd.read_parquet(path)
    if src.platform == "arcgis":
        gdf = _fetch_arcgis(src.service_url, src.zone_field)
    else:
        gdf = _fetch_socrata(src.socrata_domain, src.dataset_id, src.zone_field)
    if src.get("source_crs"):
        # Some portals label projected coordinates as WGS 84; the registry overrides it
        gdf = gdf.set_crs(src.source_crs, allow_override=True).to_crs("EPSG:4326")
    gdf = gdf.rename(columns={src.zone_field: "local_zone"})[["local_zone", "geometry"]]
    gdf = gdf[gdf.geometry.notna() & ~gdf.geometry.is_empty]
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    gdf.to_parquet(path)
    return gdf


# --- comparison ------------------------------------------------------------

def normalize(code: object) -> str:
    """Letters and digits only, upper-cased: 'R-1' == 'R1', 'OS/(RCA' == 'OS (RCA)'.

    Regrid truncates or re-punctuates some codes (dropped closing parentheses,
    '/' for ',' or ':'), so punctuation is ignored when comparing.
    """
    return re.sub(r"[^0-9A-Za-z]", "", str(code or "")).upper()


def _exact(code: object) -> str:
    return str(code or "").strip().upper()


def regrid_zoning(municipality_id: int) -> gpd.GeoDataFrame:
    return gpd.read_postgis(
        f"select zoning as regrid_zone, geometry from {SOURCE_TABLE} where municipality_id = %(m)s",
        get_engine(), geom_col="geometry", params={"m": int(municipality_id)},
    )


def _crosswalk(municipality_id: int) -> dict:
    """Curated Regrid -> local code equivalences (normalized) for one jurisdiction."""
    if not CROSSWALK.exists():
        return {}
    cw = pd.read_csv(CROSSWALK, dtype=str, keep_default_na=False)
    cw = cw[(cw.municipality_id == str(municipality_id)) & (cw.relation == "same")]
    return dict(zip(cw.regrid_code.map(normalize), cw.local_code.map(normalize)))


def rating(pct_agreement: float, pct_covered: float) -> str:
    """Accuracy of Regrid zoning for a jurisdiction, judged against the local source."""
    if pct_covered < 95:
        return "coverage gap"
    if pct_agreement >= 98:
        return "high"
    if pct_agreement >= 90:
        return "medium"
    return "low"


def compare(src: pd.Series) -> dict:
    local = fetch(src).to_crs(AREA_CRS)
    regrid = regrid_zoning(src.municipality_id).to_crs(AREA_CRS)
    local["geometry"] = local.geometry.make_valid()
    regrid["geometry"] = regrid.geometry.make_valid()

    inter = gpd.overlay(regrid, local, how="intersection", keep_geom_type=True)
    inter["area"] = inter.area
    cw = _crosswalk(src.municipality_id)
    regrid_norm = inter.regrid_zone.map(normalize).map(lambda c: cw.get(c, c))
    inter["match"] = regrid_norm == inter.local_zone.map(normalize)
    inter["exact"] = inter.regrid_zone.map(_exact) == inter.local_zone.map(_exact)

    regrid_area, local_area, both = regrid.area.sum(), local.union_all().area, inter.area.sum()
    piece_acres = inter.area / SQ_M_PER_ACRE
    core = inter[piece_acres >= SLIVER_ACRES]
    pct_core = 100 * core.loc[core.match, "area"].sum() / core.area.sum()
    substantive = inter[~inter.match & (piece_acres >= SUBSTANTIVE_ACRES)]
    mismatches = (substantive.groupby(["regrid_zone", "local_zone"]).area.sum()
                  .sort_values(ascending=False).reset_index())
    regrid_codes = set(regrid.regrid_zone.map(normalize))
    local_codes = set(local.local_zone.map(normalize)) - {""}

    return {
        "municipality_id": src.municipality_id,
        "jurisdiction": src.jurisdiction,
        **layer_metadata(src),
        "regrid_zoning_date": src.regrid_zoning_date,
        "local_features": len(local),
        "regrid_features": len(regrid),
        "local_codes": len(local_codes),
        "regrid_codes": len(regrid_codes),
        "codes_only_in_local": "; ".join(sorted(local_codes - regrid_codes)[:15]),
        "codes_only_in_regrid": "; ".join(sorted(regrid_codes - local_codes)[:15]),
        "pct_regrid_area_covered": round(100 * both / regrid_area, 1),
        "pct_local_area_covered": round(100 * both / local_area, 1),
        "pct_exact_code_agreement": round(100 * inter.loc[inter.exact, "area"].sum() / both, 1),
        "pct_code_agreement": round(100 * inter.loc[inter.match, "area"].sum() / both, 1),
        "pct_agreement_excl_slivers": round(pct_core, 1),
        "acres_disagreeing": round(inter.loc[~inter.match, "area"].sum() / SQ_M_PER_ACRE),
        "acres_substantive_disagreement": round(substantive.area.sum() / SQ_M_PER_ACRE),
        "accuracy_rating": rating(pct_core, 100 * both / regrid_area),
        "top_mismatches": "; ".join(
            f"{r.regrid_zone}->{r.local_zone} ({r.area / SQ_M_PER_ACRE:,.0f} ac)"
            for r in mismatches.head(5).itertuples()
        ),
        "compared_on": date.today(),
    }


def _registry() -> pd.DataFrame:
    return pd.read_csv(REGISTRY, dtype={"municipality_id": int}, keep_default_na=False)


def main() -> None:
    cmd, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("compare", [])
    if cmd == "discover":
        print(discover(" ".join(args)).to_string(index=False))
        return
    reg = _registry()
    reg = reg[reg.status == "active"]
    if args:
        reg = reg[reg.municipality_id.isin([int(a) for a in args])]
    rows = []
    for src in reg.itertuples(index=False):
        print(f"comparing {src.jurisdiction} ...", flush=True)
        try:
            rows.append(compare(pd.Series(src._asdict())))
        except Exception as exc:  # keep going; record the failure
            rows.append({"municipality_id": src.municipality_id, "jurisdiction": src.jurisdiction,
                         "error": str(exc)[:200], "compared_on": date.today()})
    out = pd.DataFrame(rows)
    if RESULTS.exists():
        old = pd.read_csv(RESULTS)
        out = pd.concat([old[~old.municipality_id.isin(out.municipality_id)], out], ignore_index=True)
    out.sort_values("jurisdiction").to_csv(RESULTS, index=False)
    print(out.drop(columns=["codes_only_in_local", "codes_only_in_regrid", "top_mismatches"],
                   errors="ignore").to_string(index=False))


if __name__ == "__main__":
    main()
