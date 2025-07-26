# backend/models/event.py

from pydantic import BaseModel
from typing import Optional

class NormalizedEvent(BaseModel):
    """
    A standardized event model to normalize data across multiple sources (e.g., SeatGeek, Ticketmaster).
    """
    title: str
    description: str
    location: str             # e.g. "New York, NY"

    venue_name: Optional[str] = None
    venue_address: Optional[str] = None     # street address
    venue_full_address: Optional[str] = None  # street + extended
    venue_type: Optional[str] = None

    price: str
    ticket_url: str
    source: str

    date: str                 # YYYY-MM-DD
    start_date: str           # same as date
    start_time: str           # e.g. "7:30 PM"
    start_datetime: str       # ISO datetime or date string

    latitude: Optional[float] = None
    longitude: Optional[float] = None

    category: Optional[str] = None              # e.g. segment/genre.name or type
    venue_phone: Optional[str] = None           # boxOfficeInfo.phoneNumberDetail
    accepted_payment: Optional[str] = None      # boxOfficeInfo.acceptedPaymentDetail
    parking_detail: Optional[str] = None        # parkingDetail

