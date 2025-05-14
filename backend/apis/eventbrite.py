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

    data = response.json().get("events", [])

    normalized = []
    for event in data:
        normalized.append(NormalizedEvent(
            title=event.get("name", {}).get("text", "No title"),
            description=event.get("description", {}).get("text", "No description"),
            location=event.get("venue", {}).get("address", {}).get("localized_address_display", "Unknown Location"),
            price="Free" if event.get("is_free") else "Paid",
            ticket_url=event.get("url", ""),
            source="Eventbrite",
            latitude=str(event.get("venue", {}).get("latitude")),
            longitude=str(event.get("venue", {}).get("longitude")),
        ))
    return normalized