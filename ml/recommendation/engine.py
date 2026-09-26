"""
Recommendation Engine for Local & Experiences.
Scores candidate experiences using the trained scikit-learn RandomForestClassifier
and ColumnTransformer pipeline matching the Jupyter Notebook source of truth.
"""
from typing import Any, Dict, List, Optional, Union
import logging
import os
from pathlib import Path
import joblib
import numpy as np
import pandas as pd

from ml.preprocessing.features import (
    FEATURE_COLS,
    build_feature_dataframe,
    calculate_haversine_distance,
    compute_interest_overlap,
    tokenize_interests,
)

logger = logging.getLogger(__name__)


def haversine_km(
    lat1: Union[float, np.ndarray, pd.Series],
    lon1: Union[float, np.ndarray, pd.Series],
    lat2: Union[float, np.ndarray, pd.Series],
    lon2: Union[float, np.ndarray, pd.Series],
) -> Union[float, np.ndarray, pd.Series]:
    """
    Haversine great-circle distance in kilometers.
    Matches exact Jupyter Notebook implementation.
    """
    R = 6371.0
    lat1, lon1, lat2, lon2 = map(np.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = np.sin(dlat / 2.0) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon / 2.0) ** 2
    a = np.clip(a, 0.0, 1.0)
    return 2 * R * np.arcsin(np.sqrt(a))


class RecommendationEngine:
    """
    Core scoring, ranking, and itinerary engine for Local & Experiences discovery.
    100% consistent with the Jupyter Notebook source of truth.
    """

    def __init__(
        self,
        model_dir: Optional[Union[str, Path]] = None,
        dataset_dir: Optional[Union[str, Path]] = None,
        pipeline_filename: str = "preprocessing_pipeline.pkl",
        model_filename: str = "recommendation_model.pkl",
        dataset_filename: str = "all_experiences_with_photos.csv",
    ):
        base_dir = Path(__file__).resolve().parent.parent

        self.model_dir = (
            Path(model_dir)
            if model_dir
            else Path(os.getenv("MODEL_DIR", base_dir / "models"))
        )
        self.dataset_dir = (
            Path(dataset_dir)
            if dataset_dir
            else Path(os.getenv("DATASET_DIR", base_dir / "datasets"))
        )

        self.pipeline_path = self.model_dir / pipeline_filename
        self.model_path = self.model_dir / model_filename
        self.dataset_path = self.dataset_dir / dataset_filename

        self.preprocessor = None
        self.model = None
        self.experiences_df: pd.DataFrame = pd.DataFrame()

        self._load_artifacts()

    def _load_artifacts(self) -> None:
        """Load trained preprocessing pipeline, model, and experiences with images dataset."""
        if not self.pipeline_path.exists():
            raise FileNotFoundError(f"Preprocessing pipeline not found at {self.pipeline_path}")
        if not self.model_path.exists():
            raise FileNotFoundError(f"Recommendation model not found at {self.model_path}")
        
        # Resolve dataset candidate in priority order
        candidates_to_check = [
            self.dataset_dir / "all_experiences_with_photos.csv",
            self.dataset_dir / "all_experiences_with_images.csv",
            self.dataset_dir / "all_experiences_cleaned.csv",
        ]
        chosen_path = None
        if self.dataset_path.exists():
            chosen_path = self.dataset_path
        else:
            for cand in candidates_to_check:
                if cand.exists():
                    chosen_path = cand
                    break
        if not chosen_path:
            raise FileNotFoundError(f"Experience dataset not found at {self.dataset_path}")
        self.dataset_path = chosen_path

        logger.info(f"Loading preprocessing pipeline from {self.pipeline_path}")
        self.preprocessor = joblib.load(self.pipeline_path)

        logger.info(f"Loading recommendation model from {self.model_path}")
        self.model = joblib.load(self.model_path)

        logger.info(f"Loading experiences dataset from {self.dataset_path}")
        self.experiences_df = pd.read_csv(self.dataset_path)

        # Ensure image_url is populated with verified images
        cat_defaults = {
            "Heritage": "https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&q=80",
            "Food": "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=800&q=80",
            "Culture": "https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=800&q=80",
            "Nature": "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80",
            "Adventure": "https://images.unsplash.com/photo-1533240332313-0db49b459ad6?w=800&q=80",
            "Religious": "https://images.unsplash.com/photo-1609766857041-ed402ea8069a?w=800&q=80",
            "Museum": "https://images.unsplash.com/photo-1565008447742-97f6f38c985c?w=800&q=80",
            "Beach": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80",
            "Shopping": "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80",
        }
        if "image_url" in self.experiences_df.columns:
            def _resolve_img(row):
                url = row.get("image_url")
                if pd.notna(url) and str(url).strip() and str(url).strip().lower() != "nan":
                    return str(url).strip()
                cat = str(row.get("category", "Heritage"))
                return cat_defaults.get(cat, "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80")
            self.experiences_df["image_url"] = self.experiences_df.apply(_resolve_img, axis=1)

        logger.info(f"Loaded {len(self.experiences_df)} experiences with images.")

    def get_experiences_df(self) -> pd.DataFrame:
        """Return the current in-memory experiences DataFrame."""
        return self.experiences_df

    def set_experiences_df(self, df: pd.DataFrame) -> None:
        """Update the in-memory experiences DataFrame (e.g. from Supabase sync)."""
        if df is not None and not df.empty:
            self.experiences_df = df
            logger.info(f"Updated in-memory experiences DataFrame with {len(df)} records.")

    def reload_dataset(self) -> None:
        """Reload the experiences dataset from disk."""
        self.experiences_df = pd.read_csv(self.dataset_path)
        logger.info(f"Reloaded {len(self.experiences_df)} experiences from disk.")

    def get_scored_candidates(
        self,
        budget_inr: float,
        available_time_hours: float,
        traveler_count: int,
        group_type: str,
        interests: Union[str, List[str]],
        user_lat: Optional[float] = None,
        user_lon: Optional[float] = None,
        radius_km: float = 25.0,
    ) -> pd.DataFrame:
        """
        Exact implementation of Jupyter Notebook CELL 33: get_scored_candidates.
        Filters by distance (if user_lat/user_lon given), scores every candidate with the model.
        """
        if self.experiences_df.empty:
            return pd.DataFrame()

        df_exp = self.experiences_df.copy()

        # Start with experiences having valid duration
        candidates = df_exp[df_exp["duration_hours_clean"].notna()].copy()

        if user_lat is not None and user_lon is not None:
            candidates = candidates[
                candidates["latitude"].notna() & candidates["longitude"].notna()
            ].copy()
            candidates["distance_km"] = haversine_km(
                user_lat, user_lon, candidates["latitude"], candidates["longitude"]
            )
            candidates = candidates[candidates["distance_km"] <= radius_km].copy()
            if candidates.empty:
                logger.info(f"No experiences within {radius_km} km of ({user_lat}, {user_lon})")
                return pd.DataFrame()
        else:
            candidates["distance_km"] = np.nan

        # Format interests string for tokenization
        if isinstance(interests, list):
            interests_str = "|".join([str(i) for i in interests if i])
        else:
            interests_str = str(interests) if interests else ""

        rows = []
        for _, exp in candidates.iterrows():
            oc, orat = compute_interest_overlap(
                interests_str, exp.get("tags"), exp.get("category"), exp.get("best_for")
            )
            price = exp.get("price_inr_clean", exp.get("price_inr", 0.0))
            duration = exp.get("duration_hours_clean", exp.get("duration_hours", 1.0))
            min_g = exp.get("min_group_size", 1)
            min_g = 1 if pd.isna(min_g) or min_g <= 0 else float(min_g)
            max_g = exp.get("max_group_size")
            max_g = 999 if pd.isna(max_g) else float(max_g)

            rating_val = exp.get("rating")
            rating_missing_val = int(exp.get("rating_missing", pd.isna(rating_val)))
            local_exp_val = int(bool(exp.get("local_experience_bool", exp.get("local_experience", True))))
            hidden_gem_val = int(bool(exp.get("hidden_gem_bool", exp.get("hidden_gem", False))))

            rows.append({
                "experience_id": str(exp.get("experience_id", "")),
                "experience_name": str(exp.get("experience_name", "")),
                "image_url": str(exp.get("image_url", "")) if pd.notna(exp.get("image_url")) else None,
                "city": str(exp.get("city", "")),
                "district": str(exp.get("district", "")) if pd.notna(exp.get("district")) else None,
                "state": str(exp.get("state", "")) if pd.notna(exp.get("state")) else None,
                "latitude": exp.get("latitude"),
                "longitude": exp.get("longitude"),
                "distance_km": exp.get("distance_km"),
                "budget_inr": float(budget_inr),
                "available_time_hours": float(available_time_hours),
                "traveler_count": int(traveler_count),
                "price_inr_clean": float(price) if pd.notna(price) else 0.0,
                "duration_hours_clean": float(duration) if pd.notna(duration) else 1.0,
                "rating": float(rating_val) if pd.notna(rating_val) else np.nan,
                "review_count": int(exp.get("review_count", 0)) if pd.notna(exp.get("review_count")) else None,
                "price_diff": float(budget_inr) - float(price) if pd.notna(price) else np.nan,
                "time_diff": float(available_time_hours) - float(duration) if pd.notna(duration) else np.nan,
                "interest_overlap_count": oc,
                "interest_overlap_ratio": orat,
                "affordable": int(float(price) <= float(budget_inr)) if pd.notna(price) else 0,
                "fits_time": int(float(duration) <= float(available_time_hours)) if pd.notna(duration) else 0,
                "group_size_ok": int(min_g <= float(traveler_count) <= max_g),
                "local_experience_bool": local_exp_val,
                "hidden_gem_bool": hidden_gem_val,
                "rating_missing": rating_missing_val,
                "group_type": str(group_type),
                "category": str(exp.get("category", "General")),
                "sub_category": str(exp.get("sub_category", "General")),
                "indoor_outdoor_clean": str(exp.get("indoor_outdoor_clean", exp.get("indoor_outdoor", "Flexible"))),
                "tags": str(exp.get("tags", "")),
                "best_for": str(exp.get("best_for", "")),
                "description": str(exp.get("description", "")),
            })

        feat_df = pd.DataFrame(rows)
        if feat_df.empty:
            return pd.DataFrame()

        Xt = self.preprocessor.transform(feat_df[FEATURE_COLS])
        probs = self.model.predict_proba(Xt)
        feat_df["recommendation_score"] = probs[:, 1] if probs.shape[1] > 1 else probs[:, 0]
        return feat_df

    def recommend(
        self,
        budget_inr: float,
        available_time_hours: float,
        traveler_count: int,
        group_type: str,
        interests: Union[str, List[str]],
        user_lat: Optional[float] = None,
        user_lon: Optional[float] = None,
        radius_km: float = 25.0,
        city: Optional[str] = None,
        category: Optional[str] = None,
        top_n: int = 10,
        apply_hard_filters: bool = False,
    ) -> List[Dict[str, Any]]:
        """
        Score candidate experiences and return top_n ranked recommendations.
        Strictly reproduces Jupyter Notebook output.
        """
        scored_df = self.get_scored_candidates(
            budget_inr=budget_inr,
            available_time_hours=available_time_hours,
            traveler_count=traveler_count,
            group_type=group_type,
            interests=interests,
            user_lat=user_lat,
            user_lon=user_lon,
            radius_km=radius_km,
        )

        if scored_df.empty:
            return []

        # Location filter when explicit city or state requested
        if city:
            loc = city.strip().lower()
            loc_mask = (
                scored_df["city"].fillna("").str.lower().str.contains(loc, na=False)
                | scored_df["district"].fillna("").str.lower().str.contains(loc, na=False)
                | scored_df["state"].fillna("").str.lower().str.contains(loc, na=False)
            )
            if loc_mask.any():
                scored_df = scored_df[loc_mask].copy()

        if category:
            cat_target = str(category).strip().lower()
            def matches_cat(row):
                cat = str(row.get("category", "")).lower()
                sub_cat = str(row.get("sub_category", "")).lower()
                if cat_target == cat:
                    return True
                if cat_target == "food":
                    return cat in ["food", "street food", "local cuisine", "seafood"] or "food" in cat or "cuisine" in cat
                if cat_target == "culture":
                    return cat in ["culture", "heritage", "museum", "temple", "religious", "spiritual", "architecture", "art", "handicraft", "workshop"]
                if cat_target == "adventure":
                    return cat in ["adventure", "trekking", "water sports", "sports", "boat ride"] or "adventure" in cat
                if cat_target == "nature":
                    return cat in ["nature", "beach", "wildlife", "waterfall", "bird watching", "coastal"] or "nature" in cat
                if cat_target == "heritage":
                    return cat in ["heritage", "fort", "temple", "religious", "architecture", "museum"] or "heritage" in cat
                if cat_target == "beach":
                    return cat in ["beach", "coastal", "water sports"] or "beach" in cat
                if cat_target == "shopping":
                    return cat in ["shopping", "market", "markets", "handicraft"] or "shopping" in cat or "market" in cat
                if cat_target == "nightlife":
                    return cat in ["nightlife", "entertainment"] or "nightlife" in cat
                if cat_target in ["local experiences", "local experience", "hidden gems", "hidden gem"]:
                    return row.get("local_experience_bool") == 1 or row.get("hidden_gem_bool") == 1 or cat in ["local experience", "local_experience", "homestay", "agritourism"]
                return cat_target in cat or cat_target in sub_cat

            cat_mask = scored_df.apply(matches_cat, axis=1)
            if cat_mask.any():
                scored_df = scored_df[cat_mask].copy()

        if interests:
            interest_list = [i.strip().lower() for i in (interests if isinstance(interests, list) else str(interests).split("|")) if i.strip()]
            if interest_list:
                def matches_interests(row):
                    cat = str(row.get("category", "")).lower()
                    sub_cat = str(row.get("sub_category", "")).lower()
                    for intr in interest_list:
                        if intr == cat:
                            return True
                        if intr == "food" and (cat in ["food", "street food", "local cuisine", "seafood"] or "food" in cat or "cuisine" in cat):
                            return True
                        if intr == "culture" and (cat in ["culture", "heritage", "museum", "temple", "religious", "spiritual", "architecture", "art", "handicraft", "workshop"]):
                            return True
                        if intr == "adventure" and (cat in ["adventure", "trekking", "water sports", "sports", "boat ride"] or "adventure" in cat):
                            return True
                        if intr == "nature" and (cat in ["nature", "beach", "wildlife", "waterfall", "bird watching", "coastal"] or "nature" in cat):
                            return True
                        if intr == "heritage" and (cat in ["heritage", "fort", "temple", "religious", "architecture", "museum"] or "heritage" in cat):
                            return True
                        if intr == "beach" and (cat in ["beach", "coastal", "water sports"] or "beach" in cat):
                            return True
                        if intr == "shopping" and (cat in ["shopping", "market", "markets", "handicraft"] or "shopping" in cat or "market" in cat):
                            return True
                        if intr == "nightlife" and (cat in ["nightlife", "entertainment"] or "nightlife" in cat):
                            return True
                        if intr in ["local experiences", "local experience", "hidden gems", "hidden gem"]:
                            if row.get("local_experience_bool") == 1 or row.get("hidden_gem_bool") == 1 or cat in ["local experience", "local_experience", "homestay", "agritourism"]:
                                return True
                        if intr in cat or intr in sub_cat:
                            return True
                    return False

                interest_mask = scored_df.apply(matches_interests, axis=1)
                if interest_mask.any():
                    scored_df = scored_df[interest_mask].copy()

        if apply_hard_filters:
            hard_mask = (scored_df["affordable"] == 1) & (scored_df["fits_time"] == 1)
            if hard_mask.any():
                scored_df = scored_df[hard_mask].copy()

        # Sort strictly descending by recommendation_score
        sorted_df = scored_df.sort_values("recommendation_score", ascending=False)
        top_df = sorted_df.head(top_n)

        results: List[Dict[str, Any]] = []
        for _, row in top_df.iterrows():
            loc_str = str(row.get("city", ""))
            if row.get("district") and str(row.get("district")) != "nan" and str(row.get("district")) != "None":
                loc_str = f"{row.get('district')}, {loc_str}"

            results.append({
                "experience_id": str(row.get("experience_id", "")),
                "experience_name": str(row.get("experience_name", "")),
                "image_url": str(row.get("image_url", "")) if pd.notna(row.get("image_url")) else None,
                "city": str(row.get("city", "")),
                "district": str(row.get("district", "")) if pd.notna(row.get("district")) else None,
                "state": str(row.get("state", "")) if pd.notna(row.get("state")) else None,
                "location": loc_str,
                "category": str(row.get("category", "")),
                "sub_category": str(row.get("sub_category", "")),
                "description": str(row.get("description", "")),
                "tags": str(row.get("tags", "")),
                "best_for": str(row.get("best_for", "")),
                "price_inr": float(row.get("price_inr_clean", 0.0)),
                "duration_hours": float(row.get("duration_hours_clean", 1.0)),
                "rating": float(row.get("rating")) if pd.notna(row.get("rating")) else None,
                "review_count": int(row.get("review_count")) if pd.notna(row.get("review_count")) else None,
                "latitude": float(row.get("latitude")) if pd.notna(row.get("latitude")) else None,
                "longitude": float(row.get("longitude")) if pd.notna(row.get("longitude")) else None,
                "indoor_outdoor": str(row.get("indoor_outdoor_clean", "Flexible")),
                "local_experience": bool(row.get("local_experience_bool", True)),
                "hidden_gem": bool(row.get("hidden_gem_bool", False)),
                "distance_km": float(np.round(row["distance_km"], 2)) if pd.notna(row.get("distance_km")) else None,
                "recommendation_score": float(np.round(row["recommendation_score"], 4)),
                "interest_overlap_count": int(row["interest_overlap_count"]),
                "interest_overlap_ratio": float(np.round(row["interest_overlap_ratio"], 4)),
            })

        return results

    def build_itinerary(
        self,
        scored_df: pd.DataFrame,
        available_time_hours: float,
        budget_inr: float,
        max_stops: int = 5,
    ) -> pd.DataFrame:
        """
        Exact implementation of Jupyter Notebook CELL 34: build_itinerary.
        Uses two greedy heuristics (Score vs Score-per-hour) and picks the higher total score combination.
        """
        if scored_df.empty:
            return pd.DataFrame()

        df_ = scored_df.copy()
        df_ = df_[
            (df_["duration_hours_clean"] <= available_time_hours)
            & (df_["price_inr_clean"] <= budget_inr)
        ]
        if df_.empty:
            return pd.DataFrame()

        def greedy(sort_col: str, ascending: bool = False):
            remaining_time = available_time_hours
            remaining_budget = budget_inr
            picked = []
            for _, row in df_.sort_values(sort_col, ascending=ascending).iterrows():
                if len(picked) >= max_stops:
                    break
                if (
                    row["duration_hours_clean"] <= remaining_time
                    and row["price_inr_clean"] <= remaining_budget
                ):
                    if any(p["experience_id"] == row["experience_id"] for p in picked):
                        continue
                    picked.append(row)
                    remaining_time -= row["duration_hours_clean"]
                    remaining_budget -= row["price_inr_clean"]
            return picked

        # Heuristic A: highest score first
        option_a = greedy("recommendation_score", ascending=False)
        # Heuristic B: best score-per-hour
        df_["score_per_hour"] = df_["recommendation_score"] / df_["duration_hours_clean"].replace(0, 0.25)
        option_b = greedy("score_per_hour", ascending=False)

        best = (
            option_a
            if sum(r["recommendation_score"] for r in option_a)
            >= sum(r["recommendation_score"] for r in option_b)
            else option_b
        )

        if not best:
            return pd.DataFrame()

        itinerary = pd.DataFrame(best)

        # Order stops by nearest-neighbor distance if distance available
        if "distance_km" in itinerary.columns and itinerary["distance_km"].notna().all():
            itinerary = itinerary.sort_values("distance_km").reset_index(drop=True)

        itinerary["total_time_used"] = itinerary["duration_hours_clean"].cumsum()
        itinerary["total_budget_used"] = itinerary["price_inr_clean"].cumsum()
        return itinerary
