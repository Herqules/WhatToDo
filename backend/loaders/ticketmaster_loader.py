# backend/apis/ticketmaster.py

import httpx
import os
from typing import List
from dotenv import load_dotenv
from backend.models.event import NormalizedEvent
from datetime import datetime



load_dotenv()
TICKETMASTER_API_KEY = os.getenv("TICKETMASTER_API_KEY")

async def fetch_ticketmaster_events(location: str, query: str = "") -> List[NormalizedEvent]:
    """
    Fetch events from the Ticketmaster API and normalize their structure.
    """
    url = "https://app.ticketmaster.com/discovery/v2/events.json"
    params = {
        "apikey": TICKETMASTER_API_KEY,
        "city": location,
        "keyword": query,
        "size": 10
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)

    if response.status_code != 200:
        raise Exception(f"Ticketmaster API error: {response.text}")

    raw_events = response.json().get("_embedded", {}).get("events", [])

    normalized_events = []
    for e in raw_events:
        venue       = e.get("_embedded", {}).get("venues", [{}])[0]
        loc         = venue.get("location") or {}
        latitude    = float(loc["latitude"])  if loc.get("latitude")  else None
        longitude   = float(loc["longitude"]) if loc.get("longitude") else None

        # Price: single "$X" if min==max, else "$min - $max"
        pr  = e.get("priceRanges", [{}])[0]
        mn  = pr.get("min"); mx = pr.get("max")
        if mn is not None and mx is not None:
            price = f"${mn}" if mn == mx else f"${mn} - ${mx}"
        else:
            price = "Varies by ticket package"

        # ISO date/time (falling back to date-only)
        dates          = e.get("dates", {}).get("start") or {}
        d_raw          = dates.get("localDate", "")
        t_raw          = dates.get("localTime", "")
        iso            = f"{d_raw}T{t_raw}" if d_raw and t_raw else d_raw

        normalized_events.append(NormalizedEvent(
            title          = e.get("name", "No Title"),
            description    = e.get("info") or "No description available.",
            location       = venue.get("city", {}).get("name", "Unknown"),
            price          = price,
            date           = iso,
            start_date     = d_raw,
            start_time     = t_raw,
            start_datetime = iso,
            ticket_url     = str(e.get("url") or ""),
            source         = "Ticketmaster",
            latitude       = latitude,
            longitude      = longitude
        ))

    return normalized_events
