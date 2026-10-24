"""
Trip and Recommendation Feedback API Endpoints.
"""
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, status
from backend.app.core.security import get_optional_user_claims
from backend.app.schemas.feedback_schemas import (
    TripFeedbackCreate,
    TripFeedbackResponse,
)
from backend.app.services.feedback_service import FeedbackService

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.post("", response_model=TripFeedbackResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=TripFeedbackResponse, status_code=status.HTTP_201_CREATED, include_in_schema=False)
async def submit_feedback(
    payload: TripFeedbackCreate,
    claims: Optional[Dict[str, Any]] = Depends(get_optional_user_claims),
):
    """
    Submit feedback, ratings, and reviews for an itinerary or place recommendation.
    """
    user_id = str(claims.get("sub") or claims.get("id")) if claims else "anonymous_traveler"
    return FeedbackService.submit_feedback(user_id=user_id, payload=payload)
