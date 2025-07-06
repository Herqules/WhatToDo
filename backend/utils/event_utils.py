# backend/utils/event_utils.py

from datetime import datetime
from typing import Tuple, List
from geopy.distance import geodesic
from backend.models.event import NormalizedEvent

# ─── SYNONYMS ─────────────────────────────────────────────────────────────────
SYNONYM_MAP = {
    "concerts": "concert",
    "live music": "concert",
    "jazz concert": "jazz",
    "comedy show": "comedy",
    "comedies": "comedy",
    "plays": "theatre",
    "theaters": "theatre",
    "musics": "music",
    "standup": "comedy",
    "stand-up": "comedy",
    "hiphop": "rap",
    "hip-hop": "rap",
    "gigs": "concert",
    "recitals": "concert",
}

# ─── KEYWORD EXTRACTION ─────────────────────────────────────────────────────────
def get_keywords(interest: str) -> List[str]:
    if not interest:
        return ["music", "concert", "show"]
    return [SYNONYM_MAP.get(w.lower(), w.lower()) for w in interest.split()]

# ─── DEDUPLICATION ──────────────────────────────────────────────────────────────
def normalize_event_key(e: NormalizedEvent) -> Tuple[str, str, str]:
    title = (e.title or "").strip().lower()
    url = (e.ticket_url or "").split("?")[0]
    date = (e.date or "").split("T")[0]

    if title.endswith(" (21+)"):
        title = title.replace(" (21+)", "")

    return title, url, date

# ─── PRICE PARSING ─────────────────────────────────────────────────────────────
def parse_price(price_str: str) -> float:
    try:
        return float(price_str.replace("$", "").split(" - ")[0])
    except:
        return 0.0

# ─── FILTER PREDICATE ────────────────────────────────────────────────────────────
def event_matches(
    event: NormalizedEvent,
    user_coords: Tuple[float, float],
    min_price: float,
    max_price: float,
    radius: float,
    filter_date: str
) -> bool:
    # Price
    price_val = parse_price(event.price or "")
    if not (min_price <= price_val <= max_price):
        return False

    # Distance
    if event.latitude and event.longitude:
        try:
            dist = geodesic(
                user_coords,
                (float(event.latitude), float(event.longitude))
            ).miles
            if dist > radius:
                return False
        except:
            return False

    # Date
    if filter_date:
        try:
            user_d = datetime.strptime(filter_date, "%Y-%m-%d").date()
            evt_d = datetime.strptime(event.date.split('T')[0], "%Y-%m-%d").date()
            if user_d != evt_d:
                return False
        except:
            return False

    return True

# ─── SORTING ───────────────────────────────────────────────────────────────────
def sort_events(events: List[NormalizedEvent], sort_by: str) -> List[NormalizedEvent]:
    if "price" in sort_by:
        reverse = "desc" in sort_by.lower()
        return sorted(events, key=lambda e: parse_price(e.price or ""), reverse=reverse)
    return sorted(events, key=lambda e: (e.title or "").lower())


# ─── DEDUPE HELPER ───────────────────────────────────────────────────────────────
# ─── DEDUPE ACROSS SAME SOURCE ONLY ────────────────────────────────────────────
def dedupe(events: List[NormalizedEvent]) -> List[NormalizedEvent]:
    """
    Remove duplicates *within* each source.  Keys on (source, title, start_datetime).
    Keeps the first occurrence of each.
    """
    seen = set()
    out  = []
    for e in events:
        key = (
            e.source,
            (e.title or "").strip().lower(),
            # use full datetime if available, else date
            e.start_datetime or e.date
            # (e.start_datetime or e.date).split("T")[0] - Switch on to collapse same day shows
        )
        if key not in seen:
            seen.add(key)
            out.append(e)
    return out