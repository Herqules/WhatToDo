# backend/loaders/eventbrite_loader.py

import os, time
from typing import List
import httpx
from tenacity import AsyncRetrying, retry_if_exception_type, stop_after_attempt, wait_exponential

from backend.models.event import NormalizedEvent
from backend.utils.loggy import get_logger

logger = get_logger("loaders.eventbrite")

EVENTBRITE_TOKEN = os.getenv("EVENTBRITE_TOKEN", "").strip()
BASE_URL = "https://www.eventbriteapi.com/v3/events/search/"
MAX_RETRIES = 3
PAGE_SIZE   = 50
WITHIN      = "50mi"

async def _fetch_page(client: httpx.AsyncClient, params: dict) -> httpx.Response:
    retryer = AsyncRetrying(
        retry=retry_if_exception_type(httpx.HTTPStatusError),
        stop=stop_after_attempt(MAX_RETRIES),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        reraise=True,
    )
    async for attempt in retryer:
        with attempt:
            resp = await client.get(
                BASE_URL,
                headers={"Authorization": f"Bearer {EVENTBRITE_TOKEN}"},
                params=params,
            )
            resp.raise_for_status()
            return resp

    # shouldn't get here
    raise RuntimeError("Eventbrite retry loop exhausted")

async def fetch_eventbrite_events(
    lat: float,
    lon: float,
    query: str = "",
) -> List[NormalizedEvent]:
    """
    Fetch a single first page of Eventbrite results for (lat,lon) + query.
    """
    if not EVENTBRITE_TOKEN:
        logger.warning("EVENTBRITE_TOKEN not set — skipping Eventbrite")
        return []

    client = httpx.AsyncClient(timeout=10.0)
    start_ts = time.monotonic()
    out: List[NormalizedEvent] = []

    try:
        params = {
            "location.latitude":  lat,
            "location.longitude": lon,
            "location.within":    WITHIN,
            "expand":             "venue",
            "page":               1,
            "page_size":          PAGE_SIZE,
        }
        if query:
            params["q"] = query

        logger.info(f"Eventbrite ▶︎ q={query!r} at ({lat:.4f},{lon:.4f})")
        resp = await _fetch_page(client, params)
        events = resp.json().get("events", [])

        for e in events:
            try:
                venue = e.get("venue") or {}
                addr  = venue.get("address") or {}
                city_name = addr.get("city") or ""

                lat_s = addr.get("latitude")
                lon_s = addr.get("longitude")
                latitude  = float(lat_s) if lat_s else None
                longitude = float(lon_s) if lon_s else None

                start_iso = e.get("start", {}).get("local", "")
                date_str, time_str = (
                    start_iso.split("T") if "T" in start_iso else (start_iso, "")
                )

                out.append(NormalizedEvent(
                    title          = e.get("name", {}).get("text", "No Title"),
                    description    = e.get("description", {}).get("text") or "No description available.",
                    location       = city_name,
                    price          = "Varies by ticket package",
                    date           = date_str,
                    start_date     = date_str,
                    start_time     = time_str,
                    start_datetime = start_iso,
                    ticket_url     = e.get("url", "") or "",
                    source         = "Eventbrite",
                    latitude       = latitude,
                    longitude      = longitude,
                ))
            except Exception as ex:
                logger.warning("Skipping malformed Eventbrite entry: %s", ex)

    except httpx.HTTPStatusError as e:
        logger.error("Eventbrite API HTTP %d: %s", e.response.status_code, e.response.text)
    except Exception as e:
        logger.exception("Unexpected Eventbrite error: %s", e)
    finally:
        await client.aclose()
        took = time.monotonic() - start_ts
        logger.info("Eventbrite ◀︎ done in %.2fs — %d events", took, len(out))

    return out

