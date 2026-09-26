"""
Recommendation Service.
Coordinates between ML recommendation model, Supabase experience catalog, and traveler preferences.
"""
from pathlib import Path
from typing import Any, Dict, List, Optional
import logging
import os

from ml.recommendation.engine import RecommendationEngine
from backend.app.services.supabase_service import SupabaseService
try:
    from backend.app.schemas.recommendation_schemas import (
        RecommendationItem,
        RecommendationRequest,
        RecommendationResponse,
    )
except ImportError:
    from app.schemas.recommendation_schemas import (
        RecommendationItem,
        RecommendationRequest,
        RecommendationResponse,
    )

logger = logging.getLogger(__name__)


class RecommendationService:
    """
    Service layer for scoring and ranking personalized recommendations
    using the trained Random Forest ML model and Supabase Experience Database.
    """

    _engine_instance: Optional[RecommendationEngine] = None

    @classmethod
    def get_engine(cls) -> RecommendationEngine:
        """Singleton accessor for the RecommendationEngine ML pipeline."""
        if cls._engine_instance is None:
            backend_dir = Path(__file__).resolve().parent.parent.parent
            workspace_root = backend_dir.parent
            ml_dir = workspace_root / "ml"

            model_dir = Path(os.getenv("MODEL_DIR", ml_dir / "models"))
            dataset_dir = Path(os.getenv("DATASET_DIR", ml_dir / "datasets"))

            logger.info(f"Initializing RecommendationEngine with all_experiences_with_images.csv: model_dir={model_dir}, dataset_dir={dataset_dir}")
            cls._engine_instance = RecommendationEngine(
                model_dir=model_dir,
                dataset_dir=dataset_dir,
                dataset_filename="all_experiences_with_images.csv",
            )

        return cls._engine_instance

    @classmethod
    def get_recommendations(cls, request: RecommendationRequest) -> RecommendationResponse:
        """
        Score and rank candidate experiences for the traveler request using the notebook ML pipeline.
        """
        engine = cls.get_engine()

        # Extract normalized fields
        budget_inr = float(request.budget_inr or 2500.0)
        available_time_hours = float(request.available_time_hours or 4.0)
        traveler_count = int(request.traveler_count)
        group_type = str(request.group_type or "Solo")
        interests = request.interests if request.interests else []

        # If coordinates provided, filter by radius around user location (default 25 km)
        user_lat = request.user_lat
        user_lon = request.user_lon
        radius_km = request.radius_km or 25.0

        city_filter = request.city if request.city else None

        results = engine.recommend(
            budget_inr=budget_inr,
            available_time_hours=available_time_hours,
            traveler_count=traveler_count,
            group_type=group_type,
            interests=interests,
            user_lat=user_lat,
            user_lon=user_lon,
            radius_km=radius_km,
            city=city_filter,
            category=request.category,
            top_n=request.top_n,
            apply_hard_filters=request.apply_hard_filters,
        )

        # Fallback if hard constraints eliminated all candidates
        if not results and request.apply_hard_filters:
            results = engine.recommend(
                budget_inr=budget_inr,
                available_time_hours=available_time_hours,
                traveler_count=traveler_count,
                group_type=group_type,
                interests=interests,
                user_lat=user_lat,
                user_lon=user_lon,
                radius_km=radius_km,
                city=None,
                category=request.category,
                top_n=request.top_n,
                apply_hard_filters=False,
            )

        # Fallback if no nearby results within radius_km: expand radius to 100km
        if not results and user_lat is not None and user_lon is not None:
            results = engine.recommend(
                budget_inr=budget_inr,
                available_time_hours=available_time_hours,
                traveler_count=traveler_count,
                group_type=group_type,
                interests=interests,
                user_lat=user_lat,
                user_lon=user_lon,
                radius_km=100.0,
                city=None,
                category=request.category,
                top_n=request.top_n,
                apply_hard_filters=False,
            )

        # Fallback to catalog-wide recommendation if still no results
        if not results:
            results = engine.recommend(
                budget_inr=budget_inr,
                available_time_hours=available_time_hours,
                traveler_count=traveler_count,
                group_type=group_type,
                interests=interests,
                user_lat=None,
                user_lon=None,
                radius_km=25.0,
                city=city_filter,
                category=request.category,
                top_n=request.top_n,
                apply_hard_filters=False,
            )

        # Format items with rich explanations and valid Supabase image URLs
        items: List[RecommendationItem] = []
        for r in results:
            item = cls._format_recommendation_item(r, request)
            items.append(item)

        return RecommendationResponse(
            success=True,
            count=len(items),
            recommendations=items,
        )

    @classmethod
    def _format_recommendation_item(
        cls,
        raw: Dict[str, Any],
        request: RecommendationRequest,
    ) -> RecommendationItem:
        """Format an ML candidate result into a clean API response item with personalized rationale."""
        score = float(raw.get("recommendation_score", 0.85))
        category = str(raw.get("category", "Local Experience"))
        sub_category = str(raw.get("sub_category", ""))
        price = float(raw.get("price_inr", 0.0))
        duration_hrs = float(raw.get("duration_hours", 1.5))
        duration_mins = int(round(duration_hrs * 60))
        rating = float(raw.get("rating")) if raw.get("rating") is not None else None
        is_hidden = bool(raw.get("hidden_gem", False))
        is_local = bool(raw.get("local_experience", True))
        overlap_count = int(raw.get("interest_overlap_count", 0))

        # Contextual explanation
        reason_parts = []
        if overlap_count > 0:
            reason_parts.append(f"Matches {overlap_count} of your selected interest{'s' if overlap_count > 1 else ''}")
        if is_hidden:
            reason_parts.append("Curated hidden gem with authentic local roots")
        elif is_local:
            reason_parts.append("Authentic host-led local experience")
        if rating and rating >= 4.5:
            reason_parts.append(f"Top-rated ({rating}★)")
        if request.budget_inr and price <= (request.budget_inr * 0.4):
            reason_parts.append("Great value within your budget")

        reason = " • ".join(reason_parts) if reason_parts else f"Recommended for {request.group_type or 'you'}"

        image_url = raw.get("image_url")
        if not image_url or not str(image_url).startswith("http"):
            image_url = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80"

        loc_str = str(raw.get("location") or raw.get("city") or "")
        if raw.get("district") and str(raw.get("district")) != "nan" and str(raw.get("district")) != "None":
            loc_str = f"{raw.get('district')}, {loc_str}"

        # Parse tags
        raw_tags = raw.get("tags")
        tag_list: List[str] = []
        if isinstance(raw_tags, list):
            tag_list = [str(t).strip() for t in raw_tags if str(t).strip()]
        elif isinstance(raw_tags, str) and raw_tags.strip():
            tag_list = [t.strip() for t in raw_tags.split(";") if t.strip()]

        exp_name = str(raw.get("experience_name", "Local Experience"))

        return RecommendationItem(
            experience_id=str(raw.get("experience_id", "")),
            experience_name=exp_name,
            name=exp_name,
            image_url=image_url,
            image=image_url,
            category=category,
            sub_category=sub_category if sub_category and sub_category != "nan" else None,
            location=loc_str,
            city=str(raw.get("city", "")),
            district=str(raw.get("district")) if raw.get("district") and str(raw.get("district")) != "nan" else None,
            state=str(raw.get("state")) if raw.get("state") and str(raw.get("state")) != "nan" else None,
            price_inr=price,
            price=price,
            duration_hours=duration_hrs,
            duration_minutes=duration_mins,
            rating=rating,
            review_count=int(raw.get("review_count")) if raw.get("review_count") is not None else None,
            distance_km=float(raw.get("distance_km")) if raw.get("distance_km") is not None else None,
            recommendation_score=round(score, 4),
            score=round(score, 4),
            reason=reason,
            tags=tag_list if tag_list else None,
            best_for=str(raw.get("best_for")) if raw.get("best_for") and str(raw.get("best_for")) != "nan" else None,
            local_experience=is_local,
            hidden_gem=is_hidden,
            indoor_outdoor=str(raw.get("indoor_outdoor", "Flexible")),
            booking_required=bool(raw.get("booking_required", False)),
        )
