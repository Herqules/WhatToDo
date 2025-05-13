# backend/utils/env.py

import os
from dotenv import load_dotenv
import httpx

load_dotenv()

def get_env_variable(var_name: str) -> str:
    value = os.getenv(var_name)
    if not value:
        raise EnvironmentError(f"Missing environment variable: {var_name}")
    return value

async def get_coordinates_for_city(city: str):
    """
    Given a city name or address string, return (latitude, longitude) using OpenStreetMap.
    """
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "q": city,
        "format": "json",
        "limit": 1
    }

    headers = {
        "User-Agent": "EventScout/1.0 (eventscout@example.com)"  # required by Nominatim usage policy
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=headers)

    if response.status_code != 200:
        return None

    results = response.json()
    if not results:
        return None

    lat = float(results[0]["lat"])
    lon = float(results[0]["lon"])
    return (lat, lon)
