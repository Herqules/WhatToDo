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

        start_date_raw = e.get("dates", {}).get("start", {}).get("localDate", "")
        start_time_raw = e.get("dates", {}).get("start", {}).get("localTime", "")
        start_date = e.get("dates", {}).get("start", {}).get("localDate", "")
        start_time = e.get("dates", {}).get("start", {}).get("localTime", "")
        datetime_str = f"{start_date}T{start_time}" if start_date and start_time else start_date

        # Always build a canonical ISO datetime first
        start_datetime = (
            f"{start_date_raw}T{start_time_raw}"
            if start_date_raw and start_time_raw
            else start_date_raw
        )




        final_date = e["dates"]["start"]["localDate"]        # YYYY-MM-DD
        final_time = e["dates"]["start"]["localTime"]        # HH:MM:SS
        start_datetime = (
            f"{final_date}T{final_time}"
            if final_date and final_time
            else final_date
        )
        date = start_datetime

        date = e.get("start", {}).get("localDate", "").split("T")[0]
        normalized_events.append(NormalizedEvent(
            title=e.get("name", "No Title"),
            description=e.get("info", "No description available."),
            location=venue.get("city", {}).get("name", "Unknown"),
            price=price,
            date = datetime_str,
            start_date     = start_date,
            start_time     = start_time,
            start_datetime = start_datetime,
            ticket_url=e.get("url"),
            source="Ticketmaster",
            latitude=latitude,
            longitude=longitude
        ))

    return normalized_events
