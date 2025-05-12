from fastapi import FastAPI, HTTPException
import httpx
import os
from typing import List
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI(title="EventScout API", description="POC API for fetching and normalizing SeatGeek event data.")

# Securely load the SeatGeek API key from the environment
SEATGEEK_API_KEY = os.getenv("SEATGEEK_API_KEY")

# ----------------------------
# Data Model for Normalized Events
# ----------------------------
class NormalizedEvent(BaseModel):
    title: str
    description: str
    location: str
    price: str
    ticket_url: str
    source: str

# ----------------------------
# Utility function to fetch and normalize SeatGeek events
# ----------------------------
async def fetch_seatgeek_events(location: str, query: str = "") -> List[NormalizedEvent]:
    """
    Fetch events from SeatGeek API and normalize them for frontend display.
    Args:
        location (str): City or area to search for events
        query (str): Optional keyword or category

    Returns:
        List[NormalizedEvent]: List of normalized event data
    """
    url = "https://api.seatgeek.com/2/events"
    params = {
        "venue.city": location,
        "q": query,
        "client_id": SEATGEEK_API_KEY,
        "per_page": 10  # Limit for demonstration purposes
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)

    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail="Error fetching SeatGeek data")

    events_data = response.json().get("events", [])

    normalized_events = []
    for event in events_data:
        normalized = NormalizedEvent(
            title=event.get("title", "No Title"),
            description=event.get("description") or "No description provided.",
            location=event.get("venue", {}).get("display_location", "Unknown Location"),
            price=f"${event.get('stats', {}).get('lowest_price', 'N/A')}",
            ticket_url=event.get("url"),
            source="SeatGeek"
        )
        normalized_events.append(normalized)

    return normalized_events

# ----------------------------
# FastAPI Endpoint
# ----------------------------
@app.get("/events/seatgeek", response_model=List[NormalizedEvent])
async def get_seatgeek_events(city: str, interest: str = ""):
    """
    Endpoint to fetch and return normalized SeatGeek events for a given city and interest.
    Query Parameters:
        city (str): City to search events in.
        interest (str): Optional keyword filter (e.g., music, comedy).
    """
    events = await fetch_seatgeek_events(location=city, query=interest)
    return events

