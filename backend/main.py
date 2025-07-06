# backend/main.py

from dotenv import load_dotenv
import asyncio
from fastapi import FastAPI, HTTPException
from typing import List

from backend.models.event import NormalizedEvent
from backend.loaders.seatgeek_loader     import fetch_seatgeek_events
from backend.loaders.ticketmaster_loader import fetch_ticketmaster_events
from backend.utils.env                   import get_coordinates_for_city
from backend.utils.event_utils           import (
    get_keywords,
    dedupe,
    event_matches,
    sort_events,
)
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
    sort_by: str = "title",
    date: str = ""
):
    # 1) Geocode ONCE
    coords = await get_coordinates_for_city(city)
    if not coords:
        raise HTTPException(400, "Unable to resolve city to coordinates")
    lat, lon = coords

    # 2) Build keywords for SeatGeek & Ticketmaster
    keywords = get_keywords(interest)

    # 3) Schedule SeatGeek + Ticketmaster per keyword
    tasks = []
    for kw in keywords:
        tasks.append(fetch_seatgeek_events(city, kw))
        tasks.append(fetch_ticketmaster_events(city, kw))

    # 5) Fire them all
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # 6) Flatten + log failures
    combined: List[NormalizedEvent] = []
    for r in results:
        if isinstance(r, Exception):
            logger.warning("API error: %s", r)
        else:
            combined.extend(r)

    # 7) Deduplicate
    deduped = dedupe(combined)
    print(f"→ TOTAL combined:   {len(combined)}")
    print(f"→ TOTAL deduplicated: {len(deduped)}")

    # 8) Apply filters
    filtered = [
        e for e in deduped
        if event_matches(e, coords, min_price, max_price, radius, date)
    ]

    # 9) Sort & return
    return sort_events(filtered, sort_by)


@app.get("/events/seatgeek", response_model=List[NormalizedEvent])
async def get_seatgeek_events(city: str, interest: str = ""):
    return await fetch_seatgeek_events(city, interest)
