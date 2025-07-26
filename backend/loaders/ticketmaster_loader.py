# backend/loaders/ticketmaster_loader.py

import os
import logging
import re
import html
from typing import List
import httpx
from datetime import datetime as dt

from backend.models.event import NormalizedEvent

logger = logging.getLogger("loaders.ticketmaster")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(name)s %(message)s"))
logger.addHandler(handler)

TICKETMASTER_API_KEY = os.getenv("TICKETMASTER_API_KEY")
BASE_URL = "https://app.ticketmaster.com/discovery/v2/events.json"

async def fetch_ticketmaster_events(
    city: str,
    query: str = "",
    size: int = 10
) -> List[NormalizedEvent]:
    """
    Fetch events from Ticketmaster by city + keyword.
    Normalizes:
      - HTML stripped and entities unescaped in descriptions
      - price ranges formatted
      - date in YYYY-MM-DD
      - human-readable 12-hour time
      - deduplicates by title, datetime, location
      - fallback ticket URLs from sales.public.url
    Returns [] on any failure.
    """
    if not TICKETMASTER_API_KEY:
        logger.warning("Ticketmaster API key missing, skipping Ticketmaster loader")
        return []

    params = {
        "apikey": TICKETMASTER_API_KEY,
        "city": city,
        "keyword": query,
        "size": size
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            logger.info("Ticketmaster ▶︎ q=%r city=%r size=%d", query, city, size)
            resp = await client.get(BASE_URL, params=params)
            resp.raise_for_status()
            data = resp.json()
    except httpx.HTTPStatusError as e:
        logger.error("Ticketmaster HTTP %d: %s", e.response.status_code, e.response.text)
        return []
    except Exception:
        logger.exception("Unexpected error calling Ticketmaster")
        return []

    raw_events = data.get("_embedded", {}).get("events", [])
    normalized: List[NormalizedEvent] = []
    seen_keys = set()

    for e in raw_events:
        try:
            # 1) Build description candidates
            desc_candidates: List[str] = []
            if info := e.get("info"):
                desc_candidates.append(info)
            if note := e.get("pleaseNote"):
                desc_candidates.append(note)

            desc_field = e.get("description")
            if isinstance(desc_field, dict):
                if text := desc_field.get("text"):
                    desc_candidates.append(text)
                elif html_field := desc_field.get("html"):
                    desc_candidates.append(html_field)
            elif isinstance(desc_field, str):
                desc_candidates.append(desc_field)

            if promoter := e.get("promoter", {}):
                if pdesc := promoter.get("description"):
                    desc_candidates.append(pdesc)

            # pick the longest non-empty candidate
            raw_desc = max(
                (d.strip() for d in desc_candidates if isinstance(d, str) and d.strip()),
                key=len,
                default=""
            )
            # strip HTML tags
            desc_no_tags = re.sub(r"<[^>]+>", "", raw_desc)
            # unescape HTML entities
            desc_unescaped = html.unescape(desc_no_tags).strip()
            description = desc_unescaped or "No description available."

            # 2) Venue & coordinates
            venue = (e.get("_embedded", {}).get("venues") or [{}])[0]
            loc = venue.get("location") or {}
            latitude = float(loc.get("latitude")) if loc.get("latitude") else None
            longitude = float(loc.get("longitude")) if loc.get("longitude") else None
            loc_name = venue.get("city", {}).get("name", "Unknown")

            # 3) Price parsing
            pr = (e.get("priceRanges") or [{}])[0]
            mn, mx = pr.get("min"), pr.get("max")
            if mn is not None and mx is not None:
                price = f"${mn}" if mn == mx else f"${mn} - ${mx}"
            else:
                price = "Varies by ticket package"

            # 4) Dates & times
            dates = e.get("dates", {}).get("start") or {}
            d_raw = dates.get("localDate", "")
            t_raw = dates.get("localTime", "")
            date_part = d_raw

            if t_raw:
                try:
                    t_obj = dt.strptime(t_raw, "%H:%M:%S")
                    start_time = t_obj.strftime("%-I:%M %p")
                except ValueError:
                    start_time = t_raw
            else:
                start_time = ""

            iso = f"{d_raw}T{t_raw}" if d_raw and t_raw else d_raw

            # dedupe key (title, datetime, location)
            title = e.get("name") or "No Title"
            key = (title.lower().strip(), iso, loc_name.lower().strip())
            if key in seen_keys:
                continue
            seen_keys.add(key)

            # 5) Ticket URL fallback
            url = e.get("url") or e.get("_embedded", {}) \
                    .get("sales", {}) \
                    .get("public", {}) \
                    .get("url", "") or ""

            normalized.append(NormalizedEvent(
                title=title,
                description=description,
                location=loc_name,
                price=price,
                date=date_part,
                start_date=date_part,
                start_time=start_time,
                start_datetime=iso,
                ticket_url=url,
                source="Ticketmaster",
                latitude=latitude,
                longitude=longitude,
            ))
        except Exception as err:
            logger.error("Skipping malformed Ticketmaster event: %s", err)

    return normalized
