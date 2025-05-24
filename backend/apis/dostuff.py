import requests
import httpx
from typing import List
from bs4 import BeautifulSoup
from backend.models.event import NormalizedEvent

def fetch_dostuff_events(subdomain: str, query: str):
    url = f"https://{subdomain}/events?search={query}"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch events from {subdomain}")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    events = []

    # Parse the HTML to extract event details
    for event_item in soup.select('.event-item'):
        title = event_item.select_one('.event-title').get_text(strip=True)
        date = event_item.select_one('.event-date').get_text(strip=True)
        time = event_item.select_one('.event-time').get_text(strip=True)
        venue = event_item.select_one('.event-venue').get_text(strip=True)
        link = event_item.select_one('a')['href']

        normalized_event = NormalizedEvent(
            title=title,
            date=date,
            time=time,
            venue=venue,
            ticket_url=link,
            source="DoStuff"
        )
        events.append(normalized_event)
    
    return events

