"""
Destination Search and Geocoding API Endpoints.
"""
from fastapi import APIRouter, HTTPException, Query, status
from backend.app.schemas.destination_schemas import DestinationSearchResponse
from backend.app.services.geocoding_service import GeocodingService

router = APIRouter(prefix="/destinations", tags=["Destinations"])


@router.get("/search", response_model=DestinationSearchResponse)
async def search_destinations(
    q: str = Query(..., min_length=2, description="Destination search query, e.g. 'Jaipur' or 'Mumbai'"),
):
    """
    Search and normalize destination locations into validated geographic coordinates.
    """
    results = await GeocodingService.search_destination(q)
    return DestinationSearchResponse(
        success=True,
        query=q,
        count=len(results),
        results=results,
    )
