# backend/apis/eventbrite.py

import httpx
import os
from typing import List
from dotenv import load_dotenv
from backend.models.event import NormalizedEvent

load_dotenv()
EVENTBRITE_TOKEN = os.getenv("EVENTBRITE_API_TOKEN")

async def fetch_eventbrite_events(location: str, query: str = "") -> List[NormalizedEvent]:
    """
    Fetch and normalize events from Eventbrite's public API using a Bearer token.
    """
    url = "https://www.eventbriteapi.com/v3/events/search/"
    headers = {
        "Authorization": f"Bearer {EVENTBRITE_TOKEN}"
    }
    params = {
        "location.address": location,
        "q": query,
        "expand": "venue",
        "page_size": 10
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers, params=params)

    if response.status_code != 200:
        raise Exception(f"Eventbrite API error: {response.text}")

    raw_events = response.json().get("events", [])

    normalized = []
    for e in raw_events:
        venue = e.get("venue", {})
        lat = float(venue.get("latitude")) if venue.get("latitude") else None
        lon = float(venue.get("longitude")) if venue.get("longitude") else None

        normalized.append(NormalizedEvent(
            title=e.get("name", {}).get("text", "No Title"),
            description=e.get("description", {}).get("text", "No description."),
            location=venue.get("address", {}).get("localized_address_display", "Unknown"),
            price="Free" if e.get("is_free") else "Paid",
            ticket_url=e.get("url"),
            source="Eventbrite",
            latitude=lat,
            longitude=lon
        ))

    return normalized
