"""Separate overlay districts from base zoning.

Regrid's zoning layer is planar: overlays are not separate polygons but are
folded into the zone code (Berkeley `R-1H` = R-1 + Hillside overlay; Marin
`RMP-12.45-HOD` = RMP-12.45 + Housing Overlay Designation; San Mateo
`E2-0.5/R`; San Jose `A(PD`). This module splits combined codes into a base
district and overlay codes, kept in two curated files:

- `inventory/overlay_codes.csv`: one row per jurisdiction + Regrid code that
  carries an overlay: `base_zoning` and `overlay_codes` (`;`-separated).
  `parse_method` is `auto` (seeded by the parser) or `curated` (edited by a
  person; never overwritten).
- `inventory/overlay_definitions.csv`: one row per overlay district with a
  stable `overlay_id`, `overlay_code`, `overlay_name`, `overlay_type`.
  IDs are assigned once and never reused.

`compile` uses these to fill `zoning_compiled.base_zoning` and to build the
`zoning_overlays` (by `overlay_id`) and `zoning_overlay_links`
(`zoning_id` <-> `overlay_id`) tables.

Usage:
    python -m regional_zoning.overlays seed
"""

import re
import sys

import pandas as pd

from regional_zoning.inventory import INVENTORY_DIR

OVERLAY_CODES = INVENTORY_DIR / "overlay_codes.csv"
OVERLAY_DEFS = INVENTORY_DIR / "overlay_definitions.csv"
OVERLAY_WORDS = re.compile(r"overlay|combining", re.I)
SEPARATORS = "-/( "


def is_overlay_code(zoning_type: str, description: str) -> bool:
    """Regrid types it as Overlay, or its description names an overlay/combining district."""
    return zoning_type == "Overlay" or bool(OVERLAY_WORDS.search(description or ""))


TOKEN = re.compile(r"[^-/() ]+")


def _numeric(t: str) -> bool:
    return bool(re.fullmatch(r"[\d.]+", t))


def parse(code: str, siblings: set[str]) -> tuple[str, list[str]] | None:
    """Split a combined code into (base, overlays) using a sibling base code.

    Only called for overlay codes (see is_overlay_code). The base is the longest
    shorter code in the same jurisdiction that prefixes it. Leading numeric
    tokens after it (plan numbers, densities, lot sizes) stay with the base;
    the remaining tokens are overlays.
    """
    candidates = sorted((s for s in siblings if s != code and code.startswith(s)), key=len, reverse=True)
    for base in candidates:
        rest = code[len(base):]
        toks = list(TOKEN.finditer(rest))
        i = 0
        while i < len(toks) and _numeric(toks[i].group()):
            i += 1
        overlays = [t.group() for t in toks[i:] if not _numeric(t.group())]
        if overlays:
            cut = len(base) + (toks[i].start() if i < len(toks) else len(rest))
            return code[:cut].rstrip("-/( "), overlays
    return None


def parse_fallback(code: str, known: set[str]) -> tuple[str, list[str]] | None:
    """No base code exists on its own: peel trailing tokens that are known overlays."""
    toks = list(TOKEN.finditer(code))
    k = len(toks)
    while k > 1 and toks[k - 1].group() in known:
        k -= 1
    if k == len(toks):
        return None
    return code[:toks[k].start()].rstrip("-/( "), [t.group() for t in toks[k:]]


def _resolve_chains(df: pd.DataFrame) -> pd.DataFrame:
    """A base that is itself a combined code (C1-1.5/R4/H -> C1-1.5/R4) resolves to its own base."""
    lookup = {(r.municipality_id, r.zoning): (r.base_zoning, r.overlay_codes)
              for r in df.itertuples() if r.base_zoning}
    bases, overlays = [], []
    for r in df.itertuples():
        base, ovs, seen = r.base_zoning, r.overlay_codes.split(";") if r.overlay_codes else [], set()
        while (r.municipality_id, base) in lookup and base not in seen:
            seen.add(base)
            parent_base, parent_ovs = lookup[(r.municipality_id, base)]
            ovs = parent_ovs.split(";") + ovs
            base = parent_base
        bases.append(base)
        overlays.append(";".join(dict.fromkeys(ovs)))
    return df.assign(base_zoning=bases, overlay_codes=overlays)


def seed() -> tuple[pd.DataFrame, pd.DataFrame]:
    codes = pd.read_csv(INVENTORY_DIR / "zoning_codes.csv", dtype={"zoning": str}, keep_default_na=False)
    codes = codes[codes.in_region.astype(str) == "True"]
    rows, pending = [], []
    for muni, grp in codes.groupby("municipality_id"):
        siblings = set(grp.zoning)
        for r in grp.itertuples():
            if not is_overlay_code(r.zoning_type, r.zoning_description):
                continue
            parsed = parse(r.zoning, siblings)
            if parsed:
                base, tokens = parsed
                rows.append(dict(municipality_id=muni, jurisdiction=r.jurisdiction, zoning=r.zoning,
                                 zoning_description=r.zoning_description, base_zoning=base,
                                 overlay_codes=";".join(tokens), parse_method="auto", notes=""))
            else:
                pending.append(r)
    # Second pass: overlay tokens learned from the first pass, region-wide
    known = {t for row in rows for t in row["overlay_codes"].split(";")}
    for r in pending:
        muni = r.municipality_id
        parsed = parse_fallback(r.zoning, known)
        if parsed and parsed[0]:
            base, tokens = parsed
            rows.append(dict(municipality_id=muni, jurisdiction=r.jurisdiction, zoning=r.zoning,
                             zoning_description=r.zoning_description, base_zoning=base,
                             overlay_codes=";".join(tokens), parse_method="auto",
                             notes="Base code not in Regrid on its own; split on known overlay tokens; review"))
        else:
            # Overlay named in the code but no base district found: flag for curation
            rows.append(dict(municipality_id=muni, jurisdiction=r.jurisdiction, zoning=r.zoning,
                             zoning_description=r.zoning_description, base_zoning="",
                             overlay_codes="", parse_method="auto",
                             notes="Overlay in description but no base code found; curate"))
    auto = _resolve_chains(pd.DataFrame(rows))

    # Curated rows win over the parser
    if OVERLAY_CODES.exists():
        old = pd.read_csv(OVERLAY_CODES, dtype={"zoning": str}, keep_default_na=False)
        curated = old[old.parse_method == "curated"]
        auto = auto.merge(curated[["municipality_id", "zoning"]], how="left", indicator=True)
        auto = pd.concat([auto[auto._merge == "left_only"].drop(columns="_merge"), curated], ignore_index=True)
    auto = auto.sort_values(["jurisdiction", "zoning"])

    # Overlay definitions with stable IDs
    pairs = (auto[auto.overlay_codes != ""]
             .assign(overlay_code=auto.overlay_codes.str.split(";")).explode("overlay_code")
             [["municipality_id", "jurisdiction", "overlay_code"]].drop_duplicates())
    if OVERLAY_DEFS.exists():
        defs = pd.read_csv(OVERLAY_DEFS, keep_default_na=False)
    else:
        defs = pd.DataFrame(columns=["overlay_id", "municipality_id", "jurisdiction", "overlay_code",
                                     "overlay_name", "overlay_type", "source_url", "notes"])
    known = set(zip(defs.municipality_id.astype(int), defs.overlay_code))
    new = pairs[[(int(m), c) not in known for m, c in zip(pairs.municipality_id, pairs.overlay_code)]].copy()
    next_id = int(defs.overlay_id.max()) + 1 if len(defs) else 1
    new.insert(0, "overlay_id", range(next_id, next_id + len(new)))
    for c in ("overlay_name", "overlay_type", "source_url", "notes"):
        new[c] = ""
    defs = pd.concat([defs, new], ignore_index=True)

    auto.to_csv(OVERLAY_CODES, index=False)
    defs.to_csv(OVERLAY_DEFS, index=False)
    return auto, defs


def main() -> None:
    if (sys.argv[1:] or ["seed"])[0] == "seed":
        codes, defs = seed()
        parsed = codes[codes.base_zoning != ""]
        print(f"{OVERLAY_CODES.name}: {len(codes):,} combined codes "
              f"({len(parsed):,} parsed, {len(codes) - len(parsed):,} need curation) "
              f"in {codes.municipality_id.nunique()} jurisdictions")
        print(f"{OVERLAY_DEFS.name}: {len(defs):,} overlay districts")


if __name__ == "__main__":
    main()
