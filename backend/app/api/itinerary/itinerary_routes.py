"""
Itinerary API Endpoints.
Exposes POST /api/itinerary/generate to synthesize chronological itineraries from selected experiences.
"""
from fastapi import APIRouter, HTTPException, status
try:
    from backend.app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
    )
    from backend.app.services.itinerary_service import ItineraryService
except ImportError:
    from app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
    )
    from app.services.itinerary_service import ItineraryService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Itinerary"])


@router.post("/generate", response_model=ItineraryGenerateResponse)
@router.post("/generate/", response_model=ItineraryGenerateResponse, include_in_schema=False)
async def generate_itinerary(request: ItineraryGenerateRequest):
    """
    Generate a realistic, time-ordered, budget-aware itinerary from traveler-selected experiences.
    Takes into account exact trip start time, travel duration, opening hours, and budget.
    """
    try:
        response = ItineraryService.generate_itinerary(request)
        return response
    except ValueError as ve:
        logger.warning(f"Invalid itinerary request: {ve}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "INVALID_REQUEST",
                "message": str(ve),
            },
        )
    except Exception as e:
        logger.error(f"Error generating itinerary: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "ITINERARY_GENERATION_FAILED",
                "message": f"Failed to synthesize itinerary: {str(e)}",
            },
        )
