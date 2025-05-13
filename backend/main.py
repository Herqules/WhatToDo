import asyncio
from fastapi import FastAPI, HTTPException
from typing import List
from dotenv import load_dotenv
from backend.models.event import NormalizedEvent
from backend.apis.seatgeek import fetch_seatgeek_events
from backend.apis.ticketmaster import fetch_ticketmaster_events
from backend.apis.eventbrite import fetch_eventbrite_events
from geopy.distance import geodesic
from backend.utils.env import get_coordinates_for_city
from fastapi.middleware.cors import CORSMiddleware




# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app first
app = FastAPI(
    title="WhatToDo",
    description="Unified API for discovering events across platforms."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ----------------------------
# Unified Endpoint for All Providers
# ----------------------------
@app.get("/events/all", response_model=List[NormalizedEvent])
async def get_all_events(
    city: str,
    interest: str = "",
    min_price: float = 0,
    max_price: float = 1500,
    radius: float = 100,
    sort_by: str = "title"  # New: sort_by param
):
    """
    Fetch and filter events based on:
    - price range
    - distance from a city
    - interest keyword
    """
    try:
        # Get latitude/longitude for input city (OpenStreetMap)
        user_coords = await get_coordinates_for_city(city)
        if not user_coords:
            raise HTTPException(status_code=400, detail="Unable to resolve city to coordinates")

        # Concurrent fetch from all APIs
        results = await asyncio.gather(
            fetch_seatgeek_events(location=city, query=interest),
            fetch_ticketmaster_events(location=city, query=interest),
            fetch_eventbrite_events(location=city, query=interest)
        )

        # Merge all results
        combined = [event for source in results for event in source]

        # Apply filters
        def event_matches(event: NormalizedEvent):
            # ---- Price filter ----
            try:
                price_val = float(event.price.strip("$")) if event.price and "$" in event.price else 0
            except:
                price_val = 0
            price_ok = min_price <= price_val <= max_price

            # ---- Distance filter ----
            if event.latitude and event.longitude:
                try:
                    event_coords = (float(event.latitude), float(event.longitude))
                    distance = geodesic(user_coords, event_coords).miles
                    distance_ok = distance <= radius
                except:
                    distance_ok = False
            else:
                distance_ok = False  # no coordinates = no inclusion

            return price_ok and distance_ok

        filtered = list(filter(event_matches, combined))

        # Sort dynamically
        if sort_by == "price":
            def price_value(event):
                try:
                    return float(event.price.strip("$")) if event.price and "$" in event.price else float('inf')
                except:
                    return float('inf')
            filtered.sort(key=price_value)
        else:
            filtered.sort(key=lambda e: e.title.lower())
        
        return filtered
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ----------------------------
# Individual Endpoint (SeatGeek only)
# ----------------------------
@app.get("/events/seatgeek", response_model=List[NormalizedEvent])
async def get_seatgeek_events(city: str, interest: str = ""):
    """
    Endpoint to fetch and return normalized SeatGeek events for a given city and interest.
    """
    return await fetch_seatgeek_events(location=city, query=interest)
