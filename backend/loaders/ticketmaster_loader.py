# backend/loaders/ticketmaster_loader.py

import os
import logging
import re
import html
from typing import List, Optional
import httpx
from datetime import datetime as dt
from backend.utils.http import async_get


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
      - Extracts full venue info + flip‑side fields:
         • category (genre)
         • venue_phone
         • accepted_payment
         • parking_detail
      - Fallback to sales.public.url if url is missing
    Returns [] on any failure.
    """
    if not TICKETMASTER_API_KEY:
        logger.warning("Ticketmaster API key missing; skipping loader.")
        return []

    query = query.strip()
    if len(query) > 100:
        query = query[:100]

    params = {
        "apikey": TICKETMASTER_API_KEY,
        "city": city,
        "keyword": query,
        "size": size
    }

    # 1) Fetch raw JSON
    try:
        logger.info("Ticketmaster ▶ q=%r city=%r size=%d", query, city, size)
        data = await async_get(BASE_URL, params=params)
    except Exception as e:
        logger.error("Ticketmaster API failure: %s", e)
        return []


    raw_events = data.get("_embedded", {}).get("events", [])
    normalized: List[NormalizedEvent] = []
    seen_ids = set()

    for e in raw_events:
        tm_id = e.get("id")
        if not tm_id or tm_id in seen_ids:
            continue
        seen_ids.add(tm_id)

        try:
            # — Description —
            desc_candidates: List[str] = []
            if info := e.get("info"):
                desc_candidates.append(info)
            if note := e.get("pleaseNote"):
                desc_candidates.append(note)
            desc_field = e.get("description")
            if isinstance(desc_field, dict):
                desc_candidates.append(desc_field.get("text", "") or desc_field.get("html", ""))
            elif isinstance(desc_field, str):
                desc_candidates.append(desc_field)
            if promoter := e.get("promoter", {}):
                desc_candidates.append(promoter.get("description", ""))
            raw_desc = max((d.strip() for d in desc_candidates if d), key=len, default="")
            description = html.unescape(re.sub(r"<[^>]+>", "", raw_desc)).strip() or "No description available."

            # — Venue & coords —
            venue = (e.get("_embedded", {}).get("venues") or [{}])[0]
            loc = venue.get("location") or {}
            try:
                latitude = float(loc.get("latitude")) if loc.get("latitude") else None
                longitude = float(loc.get("longitude")) if loc.get("longitude") else None
            except ValueError:
                latitude = longitude = None

            # — Core venue fields —
            venue_name = venue.get("name")
            addr = venue.get("address", {}).get("line1")
            city_name = venue.get("city", {}).get("name")
            state_code = venue.get("state", {}).get("stateCode")
            postal    = venue.get("postalCode")
            extended  = f"{city_name}, {state_code} {postal}" if city_name and state_code and postal else None
            full_address = ", ".join(filter(None, [addr, extended])) if (addr or extended) else None

            # — Flip‑side: box office & parking —
            box_info        = venue.get("boxOfficeInfo", {}) or {}
            venue_phone     = box_info.get("phoneNumberDetail")
            accepted_payment= box_info.get("acceptedPaymentDetail")
            parking_detail  = venue.get("parkingDetail")

            # — Flip‑side: category from event classifications (genre) —
            category: Optional[str] = None
            classifications = e.get("classifications") or []
            if classifications:
                genre = classifications[0].get("genre", {}) or {}
                category = genre.get("name")

            # — Price parsing —
            pr = (e.get("priceRanges") or [{}])[0]
            mn, mx = pr.get("min"), pr.get("max")
            if mn is not None and mx is not None:
                if mn == 0 and mx == 0:
                    price = "Free"
                elif mn == mx:
                    price = f"${mn:.2f}"
                else:
                    price = f"${mn:.2f} - ${mx:.2f}"
            else:
                price = "Varies by ticket package"

            # — Date & Time —
            dates = e.get("dates", {}).get("start") or {}
            d_raw = dates.get("localDate", "") or ""
            t_raw = dates.get("localTime", "") or ""
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

            # — Ticket URL fallback —
            url = (
                e.get("url")
                or e.get("_embedded", {})
                     .get("sales", {})
                     .get("public", {})
                     .get("url", "")
            ) or ""

            normalized.append(NormalizedEvent(
                title                = e.get("name", "No Title"),
                description          = description,
                location             = city_name or "Unknown",
                venue_name           = venue_name,
                venue_address        = addr,
                venue_full_address   = full_address,
                venue_type           = classifications[0].get("segment", {}).get("name") if classifications else None,
                category             = category,
                venue_phone          = venue_phone,
                accepted_payment     = accepted_payment,
                parking_detail       = parking_detail,
                price                = price,
                price_min=mn if mn is not None else None,
                price_max=mx if mx is not None else None,
                ticket_url           = url,
                source               = "Ticketmaster",
                date                 = date_part,
                start_date           = date_part,
                start_time           = start_time,
                start_datetime       = iso,
                latitude             = latitude,
                longitude            = longitude,
            ))

        except Exception as err:
            logger.error("Skipping malformed TM event %s: %s", tm_id, err)

    return normalized
