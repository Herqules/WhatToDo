# backend/loaders/seatgeek_loader.py

from typing import List, Any, Dict
from datetime import datetime
from backend.config.settings import (
    SEATGEEK_API_URL,
    SEATGEEK_CLIENT_ID,
    SEATGEEK_CLIENT_SECRET,
)
from backend.models.event import NormalizedEvent
from backend.utils.http import async_get
from backend.utils.env import get_coordinates_for_city

async def fetch_seatgeek_events(
    location: str,
    query: str = "",
    per_page: int = 10,
) -> List[NormalizedEvent]:
    """
    Fetch events from SeatGeek using lat/lon + range, with retry/back-off.
    Normalizes:
      - price to a string (empty if unavailable)
      - date in YYYY-MM-DD
      - start_time in h:mm AM/PM (empty if unavailable)
    Returns [] on any failure.
    """
    # 1) Geocode the city
    coords = await get_coordinates_for_city(location)
    if not coords:
        print(f"⚠️ SeatGeek: could not geocode '{location}'")
        return []
    lat, lon = coords

    # 2) Build API params
    params: Dict[str, Any] = {
        "client_id": SEATGEEK_CLIENT_ID,
        "client_secret": SEATGEEK_CLIENT_SECRET,
        "lat": lat,
        "lon": lon,
        "range": "50mi",
        "q": query,
        "per_page": per_page,
    }

    # 3) Fetch with retries
    try:
        data = await async_get(SEATGEEK_API_URL, params=params)
    except Exception as e:
        print(f"⚠️ SeatGeek API error: {e}")
        return []

    events_raw = data.get("events", [])
    normalized: List[NormalizedEvent] = []

    for item in events_raw:
        try:
            # — Price (always emit a string) —
            stats = item.get("stats", {})
            low = stats.get("lowest_price")
            high = stats.get("highest_price")
            if low and high:
                price_str = f"${low}–${high}"
            elif low:
                price_str = f"Starting at ${low}"
            else:
                price_str = "Varies by seating/ticket tier"

            # — Date & Time (always emit strings) —
            dt_local = item.get("datetime_local", "")
            date_part = ""
            time_part = ""
            if dt_local:
                try:
                    dt = datetime.fromisoformat(dt_local)
                    date_part = dt.strftime("%Y-%m-%d")
                    time_part = dt.strftime("%-I:%M %p")  # e.g. "7:30 PM"
                except ValueError:
                    parts = dt_local.split("T")
                    date_part = parts[0]
                    time_part = parts[1] if len(parts) > 1 else ""

            # — Venue location —
            venue = item.get("venue", {})
            loc_name = venue.get("display_location", "")
            lat_v = venue.get("location", {}).get("lat")
            lon_v = venue.get("location", {}).get("lon")

            normalized.append(NormalizedEvent(
                title=item.get("title", "No Title"),
                description=item.get("description") or "No description available.",
                location=loc_name,
                price=price_str,
                date=date_part,
                start_time=time_part,
                ticket_url=item.get("url", ""),
                source="SeatGeek",
                latitude=str(lat_v) if lat_v is not None else None,
                longitude=str(lon_v) if lon_v is not None else None,
            ))
        except Exception as err:
            print(f"⚠️ Skipping malformed SeatGeek event: {err}")

    return normalized
