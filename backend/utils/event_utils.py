# backend/utils/event_utils.py

"""
Utilities for keyword extraction, deduplication, filtering, and sorting of normalized events.
"""
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
    """
    Map raw user interest words to normalized keywords.
    """
    if not interest:
        return ["music", "concert", "show"]
    return [SYNONYM_MAP.get(w.lower(), w.lower()) for w in interest.split()]

# ─── DEDUPE ACROSS SAME SOURCE ONLY ────────────────────────────────────────────
def dedupe(events: List[NormalizedEvent]) -> List[NormalizedEvent]:
    """
    Remove duplicates within each source, based on (source, title, date).
    Keeps the first occurrence of each.
    """
    seen = set()
    out: List[NormalizedEvent] = []
    for e in events:
        key = (
            e.source,
            (e.title or "").strip().lower(),
            e.date  # ISO string; includes time if present
        )
        if key not in seen:
            seen.add(key)
            out.append(e)
    return out

# ─── PRICE PARSING ─────────────────────────────────────────────────────────────
def parse_price(price_str: str) -> float:
    """
    Convert price string like "$10 - $20" to float(min).
    """
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
    # Price filter
    price_val = parse_price(event.price or "")
    if not (min_price <= price_val <= max_price):
        return False

    # Distance filter
    if event.latitude is not None and event.longitude is not None:
        try:
            dist = geodesic(user_coords, (event.latitude, event.longitude)).miles
            if dist > radius:
                return False
        except:
            return False

    # Date filter
    if filter_date:
        try:
            user_d = datetime.strptime(filter_date, "%Y-%m-%d").date()
            evt_d = datetime.fromisoformat(event.date.split('T')[0]).date()
            if user_d != evt_d:
                return False
        except:
            return False

    return True

# ─── SORTING ───────────────────────────────────────────────────────────────────
def sort_events(events: List[NormalizedEvent], sort_by: str) -> List[NormalizedEvent]:
    """
    Sort events by price or by datetime (default).  Price sorting honors 'desc'.
    """
    if "price" in sort_by.lower():
        reverse = "desc" in sort_by.lower()
        return sorted(events, key=lambda e: parse_price(e.price or ""), reverse=reverse)

    # Default: sort by event.date ISO string or parse into datetime
    def _key(e: NormalizedEvent):
        iso = e.date or ""
        try:
            return datetime.fromisoformat(iso)
        except:
            # fallback to date-only
            try:
                return datetime.fromisoformat(iso.split('T')[0] + 'T00:00:00')
            except:
                return datetime.min

    return sorted(events, key=_key)
