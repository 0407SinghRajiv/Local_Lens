"""
Recommendation API Endpoints.
Exposes POST /api/recommendations to score and rank experiences using the ML model.
"""
from fastapi import APIRouter, HTTPException, status
try:
    from backend.app.schemas.recommendation_schemas import (
        RecommendationRequest,
        RecommendationResponse,
    )
    from backend.app.services.recommendation_service import RecommendationService
except ImportError:
    from app.schemas.recommendation_schemas import (
        RecommendationRequest,
        RecommendationResponse,
    )
    from app.services.recommendation_service import RecommendationService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Recommendations"])


@router.post("", response_model=RecommendationResponse)
@router.post("/", response_model=RecommendationResponse, include_in_schema=False)
async def get_recommendations(request: RecommendationRequest):
    """
    Score and rank personalized experience recommendations for traveler preferences.
    Uses the trained ML model, ColumnTransformer pipeline, and cleaned experience dataset.
    """
    try:
        response = RecommendationService.get_recommendations(request)
        return response
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "code": "RECOMMENDATION_FAILED",
                "message": f"Failed to score recommendations: {str(e)}",
            },
        )
