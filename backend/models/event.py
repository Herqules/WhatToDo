# backend/models/event.py

from pydantic import BaseModel
from typing import Optional

class NormalizedEvent(BaseModel):
    """
    A standardized event model to normalize data across multiple sources (e.g., SeatGeek, Ticketmaster).
    """
    title: str
    description: str
    location: str
    price: str
    ticket_url: str
    source: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
