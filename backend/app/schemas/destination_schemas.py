"""
Destination and Geocoding Schemas.
"""
from typing import List, Optional
from pydantic import BaseModel, Field


class Coordinates(BaseModel):
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)


class DestinationSearchResult(BaseModel):
    name: str
    normalized_name: str
    display_name: str
    city: str
    state: Optional[str] = None
    country: str = "India"
    coordinates: Coordinates
    timezone: str = "Asia/Kolkata"
    confidence: float = 1.0
    source: str = "geocoder"


class DestinationSearchResponse(BaseModel):
    success: bool = True
    query: str
    count: int
    results: List[DestinationSearchResult]
