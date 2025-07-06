# backend/loaders/seatgeek_loader.py

from typing import List, Any, Dict
from backend.config.settings import (
    SEATGEEK_API_URL,
    SEATGEEK_CLIENT_ID,
    SEATGEEK_CLIENT_SECRET,
)
from backend.models.event import NormalizedEvent
from backend.utils.http import async_get
from backend.utils.env import get_coordinates_for_city  # <-- new import

async def fetch_seatgeek_events(
    location: str,
    query: str = "",
    per_page: int = 10,
) -> List[NormalizedEvent]:
    """
    Fetches events from SeatGeek using lat/lon + range, with retry/back-off,
    and normalizes them into our Event model. Returns [] on any failure.
    """
    # 1) Geocode the city string into coordinates
    coords = await get_coordinates_for_city(location)
    if not coords:
        print(f"⚠️ SeatGeek: could not geocode location '{location}'")
        return []
    lat, lon = coords

    # 2) Build SeatGeek params using latitude/longitude
    params: Dict[str, Any] = {
        "client_id": SEATGEEK_CLIENT_ID,
        "client_secret": SEATGEEK_CLIENT_SECRET,
        "lat": lat,
        "lon": lon,
        "range": "50mi",     # you can adjust this radius
        "q": query,
        "per_page": per_page,
    }

    # 3) Fetch with retries/back-off
    try:
        data = await async_get(SEATGEEK_API_URL, params=params)
    except Exception as e:
        print(f"⚠️ SeatGeek API error: {e}")
        return []

    # 4) Normalize SeatGeek’s JSON into our model
    events_raw = data.get("events", [])
    normalized: List[NormalizedEvent] = []

    for item in events_raw:
        try:
            venue = item.get("venue", {})
            stats = item.get("stats", {})

            # Price formatting
            low = stats.get("lowest_price")
            high = stats.get("highest_price")
            if low and high:
                price_str = f"${low} – ${high}"
            elif low:
                price_str = f"Starting at ${low}"
            else:
                price_str = "Varies by ticket package"

            # Date and time split
            dt_local = item.get("datetime_local", "")
            date_part, time_part = (dt_local.split("T") + ["", ""])[:2]

            normalized.append(NormalizedEvent(
                title=item.get("title", "No Title"),
                description=item.get("description") or "No description available.",
                location=venue.get("display_location"),
                price=price_str,
                date=date_part,
                start_time=time_part,
                ticket_url=item.get("url"),
                source="SeatGeek",
                latitude=str(venue.get("location", {}).get("lat")) if venue.get("location") else None,
                longitude=str(venue.get("location", {}).get("lon")) if venue.get("location") else None,
            ))
        except Exception as parse_err:
            print(f"⚠️ Skipping malformed SeatGeek event: {parse_err}")

    return normalized
