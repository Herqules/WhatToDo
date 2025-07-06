import os
import httpx
from typing import List
from backend.models.event import NormalizedEvent
from dotenv import load_dotenv

load_dotenv()
YELP_API_KEY = os.getenv("YELP_API_KEY")

HEADERS = {"Authorization": f"Bearer {YELP_API_KEY}"}

async def fetch_yelp_events(location: str, query: str = "") -> List[NormalizedEvent]:
    url = "https://api.yelp.com/v3/events"
    params = {
        "location": location,
        "limit": 20,
        "sort_on": "popularity",
        "categories": query or "music,festivals,nightlife"
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=HEADERS, params=params)

    if response.status_code != 200:
        raise Exception(f"Yelp API error: {response.text}")

    data = response.json()
    events = data.get("events", [])
    normalized = []

    for e in events:
        normalized.append(NormalizedEvent(
            title=e.get("name", "No Title"),
            description=e.get("description", "No description available."),
            location=e.get("location", {}).get("address1", "Unknown"),
            price=e.get("cost", "Free") if e.get("cost") else "Varies by ticket package",
            ticket_url=e.get("event_site_url", ""),
            source="Yelp",
            latitude=e.get("latitude"),
            longitude=e.get("longitude"),
            date=e.get("time_start", "")  # ISO 8601 format, e.g., 2025-06-01T20:00:00
        ))

    return normalized

