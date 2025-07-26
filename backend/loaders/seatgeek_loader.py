# backend/loaders/seatgeek_loader.py

from typing import List, Any, Dict
from datetime import datetime
import re

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
      - strips HTML from descriptions
      - deduplicates events within SeatGeek results
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
    seen_keys = set()

    for item in events_raw:
        try:
            # — Price formatting —
            stats = item.get("stats", {})
            low = stats.get("lowest_price")
            high = stats.get("highest_price")
            if low and high:
                price_str = f"${low}–${high}"
            elif low:
                price_str = f"Starting at ${low}"
            else:
                price_str = "Varies by seating/ticket tier"

            # — Date & Time —
            iso_ts = item.get("datetime_local") or item.get("datetime_utc") or ""
            date_part = ""
            time_part = ""
            if iso_ts:
                try:
                    dt = datetime.fromisoformat(iso_ts)
                    date_part = dt.strftime("%Y-%m-%d")
                    raw_time = dt.strftime("%-I:%M %p")
                    # Hide placeholder midnight
                    time_part = "" if raw_time == "12:00 AM" else raw_time
                except ValueError:
                    parts = iso_ts.split("T", 1)
                    date_part = parts[0]
                    time_part = parts[1] if len(parts) > 1 else ""

            # — Venue location —
            venue = item.get("venue", {})
            loc_name = venue.get("display_location", "")
            lat_v = venue.get("location", {}).get("lat")
            lon_v = venue.get("location", {}).get("lon")

            # — Description cleaning —
            raw_desc = item.get("description") or ""
            desc_clean = re.sub(r"<[^>]+>", "", raw_desc).strip()
            description = desc_clean if desc_clean else "No description available."

            # — Deduplication key —
            dedupe_key = (
                item.get("title", "").strip().lower(),
                iso_ts,
                loc_name.strip().lower()
            )
            if dedupe_key in seen_keys:
                continue
            seen_keys.add(dedupe_key)

            normalized.append(NormalizedEvent(
                title=item.get("title", "No Title"),
                description=description,
                location=loc_name,
                price=price_str,
                date=date_part,
                start_date=date_part,
                start_time=time_part,
                start_datetime=iso_ts,
                ticket_url=item.get("url", "") or "",
                source="SeatGeek",
                latitude=lat_v,
                longitude=lon_v,
            ))
        except Exception as err:
            print(f"⚠️ Skipping malformed SeatGeek event: {err}")

    return normalized
