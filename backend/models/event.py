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

    # Dates & times
    date: Optional[str]          # YYYY‑MM‑DD
    start_date: Optional[str]    # same as date (or more specific)
    start_time: Optional[str]    # h:mm AM/PM or empty
    start_datetime: Optional[str]# full ISO string

    ticket_url: str
    source: str

    latitude: Optional[float] = None
    longitude: Optional[float] = None
