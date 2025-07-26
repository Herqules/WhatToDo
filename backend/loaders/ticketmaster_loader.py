# backend/loaders/ticketmaster_loader.py

import os
import logging
import re
import html
from typing import List
import httpx
from datetime import datetime as dt

from backend.models.event import NormalizedEvent

# ——— Logger setup ———
logger = logging.getLogger("loaders.ticketmaster")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(
    logging.Formatter("%(asctime)s %(levelname)-8s %(name)s %(message)s")
)
logger.addHandler(handler)

# ——— Config ———
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
      - Strips HTML tags & unescapes entities in descriptions
      - Formats price ranges
      - Dates in YYYY-MM-DD
      - Times in h:mm AM/PM
      - Deduplicates by TM event ID
      - Fallback to sales.public.url if url is missing
    Returns [] on any failure.
    """
    if not TICKETMASTER_API_KEY:
        logger.warning("Ticketmaster API key missing; skipping loader.")
        return []

    params = {
        "apikey": TICKETMASTER_API_KEY,
        "city": city,
        "keyword": query,
        "size": size
    }

    # 1) Fetch raw JSON
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            logger.info("Ticketmaster ▶ q=%r city=%r size=%d", query, city, size)
            resp = await client.get(BASE_URL, params=params)
            resp.raise_for_status()
            data = resp.json()
    except httpx.HTTPStatusError as e:
        logger.error("Ticketmaster HTTP %d: %s", e.response.status_code, e.response.text)
        return []
    except Exception as e:
        logger.exception("Unexpected Ticketmaster error: %s", e)
        return []

    raw_events = data.get("_embedded", {}).get("events", [])
    normalized: List[NormalizedEvent] = []
    seen_ids = set()

    for e in raw_events:
        # 2) Dedupe by TM’s own ID
        tm_id = e.get("id")
        if not tm_id or tm_id in seen_ids:
            continue
        seen_ids.add(tm_id)

        try:
            # — Description: pick longest candidate, strip HTML, unescape entities —
            desc_candidates: List[str] = []
            if info := e.get("info"):
                desc_candidates.append(info)
            if note := e.get("pleaseNote"):
                desc_candidates.append(note)

            desc_field = e.get("description")
            if isinstance(desc_field, dict):
                if txt := desc_field.get("text"):
                    desc_candidates.append(txt)
                elif html_txt := desc_field.get("html"):
                    desc_candidates.append(html_txt)
            elif isinstance(desc_field, str):
                desc_candidates.append(desc_field)

            if promoter := e.get("promoter", {}):
                if pdesc := promoter.get("description"):
                    desc_candidates.append(pdesc)

            raw_desc = max(
                (d.strip() for d in desc_candidates if isinstance(d, str) and d.strip()),
                key=len, default=""
            )
            desc_no_tags = re.sub(r"<[^>]+>", "", raw_desc)
            description = html.unescape(desc_no_tags).strip() or "No description available."

            # — Venue & coords —
            venue = (e.get("_embedded", {}).get("venues") or [{}])[0]
            loc = venue.get("location") or {}
            latitude = float(loc["latitude"]) if loc.get("latitude") else None
            longitude = float(loc["longitude"]) if loc.get("longitude") else None
            loc_name = venue.get("city", {}).get("name", "Unknown")

            # — Price parsing —
            pr = (e.get("priceRanges") or [{}])[0]
            mn, mx = pr.get("min"), pr.get("max")
            if mn is not None and mx is not None:
                price = f"${mn}" if mn == mx else f"${mn} - ${mx}"
            else:
                price = "Varies by ticket package"

            # — Date & Time —
            dates = e.get("dates", {}).get("start") or {}
            d_raw = dates.get("localDate", "")
            t_raw = dates.get("localTime", "")
            date_part = d_raw or ""

            if t_raw:
                try:
                    t_obj = dt.strptime(t_raw, "%H:%M:%S")
                    start_time = t_obj.strftime("%-I:%M %p")
                except ValueError:
                    start_time = t_raw
            else:
                start_time = ""

            iso = f"{d_raw}T{t_raw}" if d_raw and t_raw else d_raw

            # — Ticket URL fallback —
            url = (
                e.get("url")
                or e.get("_embedded", {})
                     .get("sales", {})
                     .get("public", {})
                     .get("url", "")
            ) or ""

            # 3) Append normalized event
            normalized.append(NormalizedEvent(
                title          = e.get("name", "No Title"),
                description    = description,
                location       = loc_name,
                price          = price,
                date           = date_part,
                start_date     = date_part,
                start_time     = start_time,
                start_datetime = iso,
                ticket_url     = url,
                source         = "Ticketmaster",
                latitude       = latitude,
                longitude      = longitude,
            ))

        except Exception as err:
            logger.error("Skipping malformed TM event %s: %s", tm_id, err)

    return normalized
