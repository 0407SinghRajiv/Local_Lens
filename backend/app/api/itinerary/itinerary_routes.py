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


@router.post("/save")
@router.post("/save/", include_in_schema=False)
async def save_itinerary(request: dict):
    """
    Save a generated itinerary to the database.
    """
    try:
        res = ItineraryService.save_itinerary(request)
        return res
    except Exception as e:
        logger.error(f"Error saving itinerary: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "ITINERARY_SAVE_FAILED",
                "message": f"Failed to save itinerary to database: {str(e)}",
            },
        )


@router.get("/list")
@router.get("/list/", include_in_schema=False)
async def list_saved_itineraries():
    """
    List all saved itineraries from the database.
    """
    try:
        items = ItineraryService.get_saved_itineraries()
        return {
            "success": True,
            "count": len(items),
            "itineraries": items,
        }
    except Exception as e:
        logger.error(f"Error listing saved itineraries: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "ITINERARY_LIST_FAILED",
                "message": f"Failed to list saved itineraries: {str(e)}",
            },
        )


@router.post("/optimize", response_model=ItineraryGenerateResponse)
@router.post("/optimize/", response_model=ItineraryGenerateResponse, include_in_schema=False)
async def optimize_itinerary(request: ItineraryGenerateRequest):
    """
    Re-optimize an itinerary route for minimum transit duration and optimal sequence.
    """
    try:
        response = ItineraryService.optimize_itinerary(request)
        return response
    except Exception as e:
        logger.error(f"Error optimizing itinerary: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "ITINERARY_OPTIMIZATION_FAILED",
                "message": f"Failed to optimize itinerary: {str(e)}",
            },
        )
