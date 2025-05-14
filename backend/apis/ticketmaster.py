# backend/apis/ticketmaster.py

import httpx
import os
from typing import List
from dotenv import load_dotenv
from backend.models.event import NormalizedEvent

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
        venue = e.get("_embedded", {}).get("venues", [{}])[0]
        location_data = venue.get("location", {})

        latitude = float(location_data.get("latitude", 0)) if location_data.get("latitude") else None
        longitude = float(location_data.get("longitude", 0)) if location_data.get("longitude") else None

        # Price filtering logic, Take Max and Min and return a range or say Varies
        price_data = e.get("priceRanges", [{}])[0]
        min_price = price_data.get("min")
        max_price = price_data.get("max")
        if min_price and max_price:
            price = f"${min_price} - ${max_price}"
        else:
            price = "Varies by ticket package"

        date = e.get("start", {}).get("localDate", "").split("T")[0]
        normalized_events.append(NormalizedEvent(
            title=e.get("name", "No Title"),
            description=e.get("info", "No description available."),
            location=venue.get("city", {}).get("name", "Unknown"),
            price=price,
            date = date,
            ticket_url=e.get("url"),
            source="Ticketmaster",
            latitude=latitude,
            longitude=longitude
        ))

    return normalized_events
