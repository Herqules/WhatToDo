# backend/config/settings.py

import os
from dotenv import load_dotenv

# Load .env from project root
load_dotenv()

# ─────── SeatGeek ───────
SEATGEEK_API_URL       = os.getenv("SEATGEEK_API_URL", "https://api.seatgeek.com/2/events")
SEATGEEK_CLIENT_ID     = os.getenv("SEATGEEK_CLIENT_ID")
SEATGEEK_CLIENT_SECRET = os.getenv("SEATGEEK_CLIENT_SECRET")

# ─────── Ticketmaster ───────
TICKETMASTER_API_URL = os.getenv(
    "TICKETMASTER_API_URL",
    "https://app.ticketmaster.com/discovery/v2/events.json"
)
TICKETMASTER_API_KEY = os.getenv("TICKETMASTER_API_KEY")

# ─────── Eventbrite ───────
EVENTBRITE_API_URL = os.getenv(
    "EVENTBRITE_API_URL",
    "https://www.eventbriteapi.com/v3/events/search/"
)
EVENTBRITE_TOKEN   = os.getenv("EVENTBRITE_TOKEN")

# ─────── RIDB ───────
RIDB_API_URL = os.getenv("RIDB_API_URL", "https://ridb.recreation.gov/api/v1/facilities")
RIDB_API_KEY = os.getenv("RIDB_API_KEY")

# ─────── Yelp ───────
YELP_API_URL = os.getenv("YELP_API_URL", "https://api.yelp.com/v3/events")
YELP_API_KEY = os.getenv("YELP_API_KEY")
