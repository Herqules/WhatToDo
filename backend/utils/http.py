# backend/utils/http.py

import asyncio
from typing import Any, Dict, Optional

import httpx

async def async_get(
    url: str,
    params: Optional[Dict[str, Any]] = None,
    headers: Optional[Dict[str, str]] = None,
    retries: int = 3,
    timeout: float = 10.0,
) -> Any:
    """
    Perform an HTTP GET with simple retry/back-off.
    Returns parsed JSON or raises on final failure.
    """
    for attempt in range(1, retries + 1):
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.get(url, params=params, headers=headers)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPError as exc:
            if attempt == retries:
                raise RuntimeError(f"GET {url} failed after {retries} attempts: {exc}")
            backoff = 2 ** attempt
            await asyncio.sleep(backoff)

