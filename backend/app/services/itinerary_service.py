"""
Itinerary Service.
Synthesizes time-ordered, budget-aware itineraries from traveler-selected experiences.
Faithfully reproduces notebook greedy optimization and geographical ordering.
"""
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
import logging
import re
import numpy as np
import pandas as pd

from ml.recommendation.engine import haversine_km
try:
    from backend.app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
        ScheduledExperience,
        SkippedExperience,
    )
    from backend.app.services.recommendation_service import RecommendationService
    from backend.app.services.routing_service import RoutingService
except ImportError:
    from app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
        ScheduledExperience,
        SkippedExperience,
    )
    from app.services.recommendation_service import RecommendationService
    from app.services.routing_service import RoutingService

logger = logging.getLogger(__name__)


class ItineraryService:
    """
    Service layer for time-aware, budget-aware, and route-optimized itinerary synthesis.
    """

    @classmethod
    def generate_itinerary(cls, request: ItineraryGenerateRequest) -> ItineraryGenerateResponse:
        """
        Synthesize a realistic chronological itinerary from selected experiences.
        """
        engine = RecommendationService.get_engine()
        experiences_df = engine.get_experiences_df()

        if experiences_df.empty:
            raise ValueError("Experience catalog is empty.")

        # 1. Filter selected experiences
        selected_ids = [str(eid).strip() for eid in request.selected_experience_ids if str(eid).strip()]

        if selected_ids:
            id_series = experiences_df["experience_id"].astype(str)
            matched_df = experiences_df[id_series.isin(selected_ids)].copy()
        else:
            # If no IDs selected, use notebook candidate scoring to pick top experiences
            scored = engine.get_scored_candidates(
                budget_inr=request.budget_inr or 4000.0,
                available_time_hours=request.available_time_hours or 5.0,
                traveler_count=request.traveler_count or 1,
                group_type=request.group_type or "Solo",
                interests=[],
                user_lat=request.user_lat,
                user_lon=request.user_lon,
            )
            matched_df = engine.build_itinerary(
                scored,
                available_time_hours=request.available_time_hours or 5.0,
                budget_inr=request.budget_inr or 4000.0,
            )

        if matched_df.empty:
            matched_df = experiences_df.head(min(max(len(selected_ids), 2), 4)).copy()

        # Parse user's start time and duration limit
        start_dt = cls._parse_start_time(request.trip_date, request.start_time)
        max_duration_minutes = int(round(float(request.available_time_hours or 5.0) * 60))
        trip_end_limit_dt = start_dt + timedelta(minutes=max_duration_minutes)

        # 2. Geographically order candidate experiences to minimize travel (Part 23)
        start_lat = request.user_lat
        start_lon = request.user_lon
        candidates = matched_df.to_dict(orient="records")
        ordered_candidates = cls._order_candidates_spatially(candidates, start_lat, start_lon)

        # 3. Time-Aware Chronological Scheduling Loop
        current_dt = start_dt
        scheduled: List[ScheduledExperience] = []
        skipped: List[SkippedExperience] = []

        total_experience_cost = 0.0
        total_transport_cost = 0.0

        current_lat = start_lat
        current_lon = start_lon

        for idx, exp in enumerate(ordered_candidates):
            exp_id = str(exp.get("experience_id", f"EXP-{idx+1}"))
            exp_name = str(exp.get("experience_name", "Local Experience"))
            cat = str(exp.get("category", "Local Experience"))
            sub_cat = str(exp.get("sub_category", "")) if pd.notna(exp.get("sub_category")) else None
            price = float(exp.get("price_inr_clean", exp.get("price_inr", 0.0)))
            duration_hrs = float(exp.get("duration_hours_clean", exp.get("duration_hours", 1.5)))
            duration_mins = max(30, int(round(duration_hrs * 60)))
            rating = float(exp.get("rating")) if pd.notna(exp.get("rating")) else None
            lat = float(exp.get("latitude")) if pd.notna(exp.get("latitude")) else None
            lon = float(exp.get("longitude")) if pd.notna(exp.get("longitude")) else None

            # Calculate transit time from current position to this experience
            if current_lat is not None and current_lon is not None and lat is not None and lon is not None:
                transit_info = RoutingService.get_travel_time(current_lat, current_lon, lat, lon)
            else:
                dist_approx = float(exp.get("distance_km", 3.0)) if pd.notna(exp.get("distance_km")) else 3.0
                transit_info = {
                    "distance_km": dist_approx,
                    "duration_minutes": max(10, int(dist_approx * 3)),
                    "estimated_fare_inr": max(50.0, dist_approx * 15.0),
                }

            transit_mins = transit_info["duration_minutes"] if len(scheduled) > 0 else 0
            transit_cost = transit_info["estimated_fare_inr"] if len(scheduled) > 0 else 0.0

            # Projected time window for this experience
            activity_start_dt = current_dt + timedelta(minutes=transit_mins)
            activity_end_dt = activity_start_dt + timedelta(minutes=duration_mins)

            # Check 1: Total Trip Duration Constraint
            if activity_end_dt > trip_end_limit_dt:
                skipped.append(SkippedExperience(
                    experience_id=exp_id,
                    name=exp_name,
                    reason=f"Insufficient remaining time within {request.available_time_hours:.1f} hours duration window",
                ))
                continue

            # Update previous stop's travel_to_next
            if scheduled:
                scheduled[-1].travel_to_next_minutes = transit_mins
                scheduled[-1].travel_to_next_distance_km = transit_info["distance_km"]

            # Format location string
            loc_str = str(exp.get("city", ""))
            if exp.get("district") and str(exp.get("district")) != "nan" and str(exp.get("district")) != "None":
                loc_str = f"{exp.get('district')}, {loc_str}"

            # Real Supabase Image URL
            image_url = exp.get("image_url")
            if not image_url or not str(image_url).startswith("http"):
                image_url = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80"

            stop_item = ScheduledExperience(
                sequence=len(scheduled) + 1,
                experience_id=exp_id,
                experience_name=exp_name,
                name=exp_name,
                category=cat,
                sub_category=sub_cat,
                location=loc_str,
                description=str(exp.get("description", "")) if pd.notna(exp.get("description")) else "",
                image_url=image_url,
                image=image_url,
                start_time=activity_start_dt.strftime("%I:%M %p"),
                end_time=activity_end_dt.strftime("%I:%M %p"),
                duration_minutes=duration_mins,
                duration_hours=duration_hrs,
                price_inr=price,
                price=price,
                rating=rating,
                distance_km=float(transit_info["distance_km"]),
                latitude=lat,
                longitude=lon,
                indoor_outdoor=str(exp.get("indoor_outdoor_clean", exp.get("indoor_outdoor", "Flexible"))),
                booking_required=bool(exp.get("booking_required_bool", exp.get("booking_required", False))),
            )

            scheduled.append(stop_item)
            total_experience_cost += price
            total_transport_cost += transit_cost
            current_dt = activity_end_dt
            if lat is not None and lon is not None:
                current_lat = lat
                current_lon = lon

        # Calculate final overview metrics
        total_duration_mins = int((current_dt - start_dt).total_seconds() // 60)
        dur_h = total_duration_mins // 60
        dur_m = total_duration_mins % 60
        dur_str = f"{dur_h}h {dur_m}m" if dur_h > 0 and dur_m > 0 else (f"{dur_h}h" if dur_h > 0 else f"{dur_m}m")

        total_cost = total_experience_cost + total_transport_cost
        budget_limit = float(request.budget_inr or 4000.0)
        budget_exceeded = total_cost > budget_limit
        budget_warning = (
            f"Estimated total (₹{total_cost:.0f}) exceeds your ₹{budget_limit:.0f} budget by ₹{total_cost - budget_limit:.0f}"
            if budget_exceeded
            else None
        )

        dest_name = request.destination or (scheduled[0].location if scheduled else "Local Explorer")

        return ItineraryGenerateResponse(
            success=True,
            destination=dest_name,
            trip_date=request.trip_date,
            start_time=start_dt.strftime("%I:%M %p"),
            end_time=current_dt.strftime("%I:%M %p"),
            total_duration_minutes=total_duration_mins,
            total_duration_formatted=dur_str,
            total_experience_cost=round(total_experience_cost, 2),
            estimated_transport_cost=round(total_transport_cost, 2),
            total_cost=round(total_cost, 2),
            budget=budget_limit,
            budget_exceeded=budget_exceeded,
            budget_warning=budget_warning,
            scheduled_experiences=scheduled,
            itinerary=scheduled,
            skipped_experiences=skipped,
        )

    @classmethod
    def _order_candidates_spatially(
        cls,
        candidates: List[Dict[str, Any]],
        start_lat: Optional[float],
        start_lon: Optional[float],
    ) -> List[Dict[str, Any]]:
        """
        Orders candidate experiences by nearest-neighbor distance to minimize travel.
        """
        if not candidates:
            return []

        if start_lat is None or start_lon is None:
            return candidates

        remaining = list(candidates)
        ordered: List[Dict[str, Any]] = []
        cur_lat = start_lat
        cur_lon = start_lon

        while remaining:
            best_idx = 0
            best_dist = float("inf")
            for i, c in enumerate(remaining):
                lat = c.get("latitude")
                lon = c.get("longitude")
                if lat is not None and lon is not None and not pd.isna(lat) and not pd.isna(lon):
                    d = haversine_km(cur_lat, cur_lon, float(lat), float(lon))
                else:
                    d = float(c.get("distance_km", 10.0)) if pd.notna(c.get("distance_km")) else 10.0

                if d < best_dist:
                    best_dist = d
                    best_idx = i

            chosen = remaining.pop(best_idx)
            ordered.append(chosen)
            if chosen.get("latitude") and chosen.get("longitude") and pd.notna(chosen["latitude"]):
                cur_lat = float(chosen["latitude"])
                cur_lon = float(chosen["longitude"])

        return ordered

    @classmethod
    def _parse_start_time(cls, trip_date_str: str, start_time_str: str) -> datetime:
        """
        Robust parser for start time formats ('10:30', '10:30 AM', '14:00', '2:30 PM').
        """
        clean_date = str(trip_date_str).strip() if trip_date_str else "2026-09-26"
        time_s = str(start_time_str).strip().upper()

        time_patterns = [
            ("%Y-%m-%d %I:%M %p", f"{clean_date} {time_s}"),
            ("%Y-%m-%d %H:%M", f"{clean_date} {time_s}"),
            ("%Y-%m-%d %I:%M%p", f"{clean_date} {time_s}"),
            ("%Y-%m-%d %I %p", f"{clean_date} {time_s}"),
        ]

        for fmt, val in time_patterns:
            try:
                return datetime.strptime(val, fmt)
            except ValueError:
                continue

        # Regex fallback for '10:30' or '10:30 AM'
        match = re.search(r"(\d{1,2}):(\d{2})\s*(AM|PM)?", time_s)
        if match:
            hour = int(match.group(1))
            minute = int(match.group(2))
            meridiem = match.group(3)
            if meridiem == "PM" and hour < 12:
                hour += 12
            elif meridiem == "AM" and hour == 12:
                hour = 0
            try:
                d = datetime.strptime(clean_date, "%Y-%m-%d")
                return d.replace(hour=hour, minute=minute, second=0)
            except Exception:
                pass

        return datetime(2026, 9, 26, 10, 30, 0)
