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
from datetime import datetime


# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="WhatToDo",
    description="Unified API for discovering events across platforms."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Update in production
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
    sort_by: str = "title",
    date: str = ""
):
    try:
        # Get city coordinates
        user_coords = await get_coordinates_for_city(city)
        if not user_coords:
            raise HTTPException(status_code=400, detail="Unable to resolve city to coordinates")

        
        # Map similar words when normalizing interests:
        synonym_map = {
            "concerts": "concert",
            "live music": "concert",
            "jazz concert": "jazz",
            "comedy show": "comedy",
            "comedies": "comedy",
            "plays": "theatre",
            "theaters": "theatre",
            "musics": "music",
            "standup": "comedy",
            "stand-up": "comedy",
            "hiphop": "rap",
            "hip-hop": "rap",
            "gigs": "concert",
            "recitals": "concert",
        }
        
        keywords = [synonym_map.get(word.lower(), word.lower()) for word in interest.split()] if interest else ["music", "concert", "show"]
        
        # Fetch for each keyword across providers
        tasks = []
        for keyword in keywords:
            tasks.extend([
                fetch_seatgeek_events(location=city, query=keyword),
                fetch_ticketmaster_events(location=city, query=keyword),
                fetch_eventbrite_events(location=city, query=keyword)
            ])

        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Combine successful results
        combined = []
        for r in results:
            if isinstance(r, Exception):
                print("⚠️ Error from API source:", r)
                continue
            combined.extend(r)

        # Deduplicate by (title, ticket_url, event date)
        unique_events = {(e.title, e.ticket_url, e.date): e for e in combined}.values()

        # Step 1: Normalize keys and deduplicate more safely
        def normalize_event_key(e):
            title = (e.title or "").strip().lower()
            url = (e.ticket_url or "").strip().lower().split("?")[0]
            date = (e.date or "").strip()

            # Optional cleanup: remove "(21+)" and truncate Eventbrite noise
            if title.endswith(" (21+)"):
                title = title.replace(" (21+)", "")
            if "eventbrite" in url:
                url_parts = url.split("/")
                url = "/".join(url_parts[:5])  # keep only the base event path

            return (title, url, date)

        seen = set()
        deduped = []

        for e in combined:
            key = normalize_event_key(e)
            if key not in seen:
                seen.add(key)
                deduped.append(e)

        print(f"→ TOTAL combined: {len(combined)}")
        print(f"→ TOTAL deduplicated: {len(deduped)}")

        # Apply filters
        def event_matches(event: NormalizedEvent):
            # ---- Price Filter ----
            try:
                price_val = float(event.price.strip("$")) if event.price and "$" in event.price else 0
            except:
                price_val = 0
            price_ok = min_price <= price_val <= max_price
            # ---- Distance Filter ----
            if event.latitude and event.longitude:
                try:
                    event_coords = (float(event.latitude), float(event.longitude))
                    distance = geodesic(user_coords, event_coords).miles
                    distance_ok = distance <= radius
                except:
                    distance_ok = False
            else:
                distance_ok = False
            
            # ---- Date Filter ----
            date_ok = True
            if date:
                try:
                    user_date = datetime.strptime(date, "%Y-%m-%d").date()
                    event_date = datetime.strptime(event.date, "%Y-%m-%d").date()
                    date_ok = event_date == user_date
                except:
                    date_ok = False

            # date_ok = event.date == date if date else True
            return price_ok and distance_ok and date_ok
        
        filtered = list(filter(event_matches, deduped))

        # Sort dynamically based on user preference
        if "price" in sort_by:
            def price_value(event):
                try:
                    return float(event.price.strip("$")) if event.price and "$" in event.price else float('inf')
                except:
                    return float('inf')
            filtered.sort(key=price_value, reverse="desc" in sort_by)
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
    return await fetch_seatgeek_events(location=city, query=interest)
