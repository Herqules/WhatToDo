# backend/apis/seatgeek.py

import httpx
import os
from typing import List
from dotenv import load_dotenv
from backend.models.event import NormalizedEvent

load_dotenv()
SEATGEEK_API_KEY = os.getenv("SEATGEEK_API_KEY")

async def fetch_seatgeek_events(location: str, query: str = "") -> List[NormalizedEvent]:
    """
    Fetch events from the SeatGeek API and normalize their structure for client use.
    """
    url = "https://api.seatgeek.com/2/events"
    params = {
        "venue.city": location,
        "q": query,
        "client_id": SEATGEEK_API_KEY,
        "per_page": 10
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)

    if response.status_code != 200:
        raise Exception(f"SeatGeek API error: {response.text}")

    events = response.json().get("events", [])

    normalized_events = []
    for e in events:
        venue = e.get("venue", {})
        stats = e.get("stats", {})

        # Long, Lat, and Venue location data
        location_data = venue.get("location", {})
        latitude = location_data.get("lat")
        longitude = location_data.get("lon")
         
         # Format price range
        min_price = stats.get("lowest_price")
        max_price = stats.get("highest_price")

        if min_price and max_price:
            price = f"${min_price} - ${max_price}"
        elif min_price:
            price = f"Starting at ${min_price}"
        else:
            price = "Varies by ticket package"

        normalized_events.append(NormalizedEvent(
            title=e.get("title", "No Title"),
            description=e.get("description") or "No description provided.",
            location=venue.get("display_location", "Unknown"),
            price=price,
            ticket_url=e.get("url"),
            source="SeatGeek",
            latitude=str(latitude) if latitude else None,
            longitude=str(longitude) if longitude else None
        ))

    return normalized_events
