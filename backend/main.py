# backend/main.py

from dotenv import load_dotenv
import asyncio
from fastapi import FastAPI, HTTPException
from typing import List

from backend.models.event import NormalizedEvent
from backend.loaders.seatgeek_loader import fetch_seatgeek_events
from backend.loaders.ticketmaster_loader import fetch_ticketmaster_events
from backend.utils.env import get_coordinates_for_city
from backend.utils.event_utils import dedupe, event_matches, sort_events
from fastapi.middleware.cors import CORSMiddleware
from backend.utils.loggy import get_logger

# 0) Load your .env before anything else
load_dotenv()

logger = get_logger("main")

app = FastAPI(
    title="WhatToDo",
    description="Unified API for discovering events across platforms."
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten up in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/events/all", response_model=List[NormalizedEvent])
async def get_all_events(
    city: str,
    interest: str = "",
    min_price: float = 0,
    max_price: float = 1500,
    radius: float = 100,
    sort_by: str = "",
    date: str = ""
):
    # 1) Geocode once
    coords = await get_coordinates_for_city(city)
    if not coords:
        raise HTTPException(400, "Unable to resolve city to coordinates")
    lat, lon = coords

    interest = interest.strip()
    sort_by = sort_by.strip().lower()

    # Sanitize sort_by
    if sort_by not in {"", "price", "title"}:
        raise HTTPException(400, f"Unsupported sort_by: {sort_by}")

    # Ensure radius is within reasonable bounds
    if radius < 0 or radius > 1000:
        raise HTTPException(400, "Radius must be between 0 and 1000 miles")

    # 2) Fetch from each source exactly once, passing the raw interest string
    results = await asyncio.gather(
        fetch_seatgeek_events(city, interest),
        fetch_ticketmaster_events(city, interest),
        return_exceptions=True
    )

    # 3) Flatten + log any loader failures
    combined: List[NormalizedEvent] = []
    for r in results:
        if isinstance(r, Exception):
            logger.warning("API error: %s", r)
        else:
            combined.extend(r)

    # 4) Deduplicate by title+date+location (cross‑source) or by event_id if you added that
    deduped = dedupe(combined)
    logger.info("→ TOTAL combined:   %d", len(combined))
    logger.info("→ TOTAL deduplicated: %d", len(deduped))

    # 5) Apply client‑side filters: interest, price, radius, date
    filtered = [
        e for e in deduped
        if event_matches(e, coords, min_price, max_price, radius, date)
    ]

    # 6) Sort & return
    return sort_events(filtered, sort_by)

@app.get("/events/seatgeek", response_model=List[NormalizedEvent])
async def get_seatgeek_events(city: str, interest: str = ""):
    return await fetch_seatgeek_events(city, interest)


@app.get("/events/ticketmaster", response_model=List[NormalizedEvent])
async def get_ticketmaster_events(
    city: str,
    interest: str = "",
    size: int = 10
) -> List[NormalizedEvent]:
    """
    Fetch Ticketmaster events by city + keyword (interest).
    """
    return await fetch_ticketmaster_events(city, interest, size)