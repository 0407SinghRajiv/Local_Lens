"""
Recommendation Engine for Local & Experiences.
Scores candidate experiences using a trained scikit-learn RandomForestClassifier
and ColumnTransformer pipeline, applies hard feasibility filters, and returns
ranked top-N results.
"""
from typing import Any, Dict, List, Optional, Union
import logging
import os
from pathlib import Path
import joblib
import numpy as np
import pandas as pd

from ml.preprocessing.features import (
    build_feature_dataframe,
    calculate_haversine_distance,
)

logger = logging.getLogger(__name__)


class RecommendationEngine:
    """
    Core scoring and ranking engine for Local & Experiences discovery.
    """

    def __init__(
        self,
        model_dir: Optional[Union[str, Path]] = None,
        dataset_dir: Optional[Union[str, Path]] = None,
        pipeline_filename: str = "preprocessing_pipeline.pkl",
        model_filename: str = "recommendation_model.pkl",
        dataset_filename: str = "all_experiences_cleaned.csv",
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
        """Load trained preprocessing pipeline, model, and cleaned dataset into memory."""
        if not self.pipeline_path.exists():
            raise FileNotFoundError(f"Preprocessing pipeline not found at {self.pipeline_path}")
        if not self.model_path.exists():
            raise FileNotFoundError(f"Recommendation model not found at {self.model_path}")
        if not self.dataset_path.exists():
            raise FileNotFoundError(f"Experience dataset not found at {self.dataset_path}")

        logger.info(f"Loading preprocessing pipeline from {self.pipeline_path}")
        self.preprocessor = joblib.load(self.pipeline_path)

        logger.info(f"Loading recommendation model from {self.model_path}")
        self.model = joblib.load(self.model_path)

        logger.info(f"Loading experiences dataset from {self.dataset_path}")
        self.experiences_df = pd.read_csv(self.dataset_path)
        logger.info(f"Loaded {len(self.experiences_df)} experiences.")

    def get_experiences_df(self) -> pd.DataFrame:
        """Return the current in-memory experiences DataFrame."""
        return self.experiences_df

    def reload_dataset(self) -> None:
        """Reload the experiences dataset from disk."""
        self.experiences_df = pd.read_csv(self.dataset_path)
        logger.info(f"Reloaded {len(self.experiences_df)} experiences from disk.")

    def add_experience_in_memory(self, new_row_dict: Dict[str, Any]) -> None:
        """Append a new experience row into the in-memory dataset."""
        new_df = pd.DataFrame([new_row_dict])
        self.experiences_df = pd.concat([self.experiences_df, new_df], ignore_index=True)

    def recommend(
        self,
        budget_inr: float,
        available_time_hours: float,
        traveler_count: int,
        group_type: str,
        interests: Union[str, List[str]],
        user_lat: Optional[float] = None,
        user_lon: Optional[float] = None,
        radius_km: Optional[float] = None,
        city: Optional[str] = None,
        category: Optional[str] = None,
        top_n: int = 10,
        apply_hard_filters: bool = True,
    ) -> List[Dict[str, Any]]:
        """
        Score all candidate experiences for a traveler request and return ranked recommendations.

        Parameters:
          - budget_inr: Total available budget in INR for an experience.
          - available_time_hours: Available time in hours.
          - traveler_count: Number of travelers.
          - group_type: Solo, Couple, Family, Friends, Group, Business, etc.
          - interests: Pipe-separated string or list of interest keywords.
          - user_lat, user_lon: Optional coordinates of traveler.
          - radius_km: Optional search radius filter in km from user_lat/user_lon.
          - city: Optional city filter (e.g. 'Delhi', 'Mumbai').
          - category: Optional category filter.
          - top_n: Number of top recommendations to return (default 10).
          - apply_hard_filters: If True, filters candidates to affordable == 1 & fits_time == 1.

        Returns:
          List of ranked dictionaries containing experience details, recommendation_score,
          and distance_km.
        """
        if self.experiences_df.empty:
            return []

        df_pool = self.experiences_df.copy()

        # Optional soft pre-filters
        if city and "city" in df_pool.columns:
            city_mask = df_pool["city"].str.strip().str.lower() == str(city).strip().lower()
            if city_mask.any():
                df_pool = df_pool[city_mask].copy()

        if category and "category" in df_pool.columns:
            cat_mask = df_pool["category"].str.strip().str.lower() == str(category).strip().lower()
            if cat_mask.any():
                df_pool = df_pool[cat_mask].copy()

        if df_pool.empty:
            return []

        # Distance calculation
        has_user_coords = (
            user_lat is not None
            and user_lon is not None
            and "latitude" in df_pool.columns
            and "longitude" in df_pool.columns
        )

        if has_user_coords:
            df_pool["distance_km"] = calculate_haversine_distance(
                user_lat, user_lon, df_pool["latitude"].values, df_pool["longitude"].values
            )
            if radius_km is not None and radius_km > 0:
                df_pool = df_pool[df_pool["distance_km"] <= radius_km].copy()
                if df_pool.empty:
                    return []
        else:
            df_pool["distance_km"] = None

        traveler_request = {
            "budget_inr": float(budget_inr),
            "available_time_hours": float(available_time_hours),
            "traveler_count": int(traveler_count),
            "group_type": str(group_type),
            "interests": interests,
        }

        # Build feature DataFrame matching FEATURE_COLS
        feature_df = build_feature_dataframe(traveler_request, df_pool)

        # Apply hard constraints if requested
        if apply_hard_filters:
            hard_mask = (feature_df["affordable"] == 1) & (feature_df["fits_time"] == 1)
            # If no candidate passes hard constraints, return empty
            if not hard_mask.any():
                return []
            df_pool = df_pool[hard_mask.values].copy()
            feature_df = feature_df[hard_mask].copy()

        if df_pool.empty:
            return []

        # Transform and score with trained RandomForest
        X_trans = self.preprocessor.transform(feature_df)
        probs = self.model.predict_proba(X_trans)

        # Class 1 is positive match
        if probs.shape[1] > 1:
            scores = probs[:, 1]
        else:
            scores = probs[:, 0]

        df_pool["recommendation_score"] = np.round(scores, 4)
        df_pool["interest_overlap_count"] = feature_df["interest_overlap_count"].values
        df_pool["interest_overlap_ratio"] = np.round(feature_df["interest_overlap_ratio"].values, 4)

        # Sort descending by recommendation_score, then tiebreak by rating / price
        df_sorted = df_pool.sort_values(
            by=["recommendation_score", "rating", "interest_overlap_ratio"],
            ascending=[False, False, False],
        )

        top_df = df_sorted.head(top_n)

        # Convert to clean dictionaries
        results: List[Dict[str, Any]] = []
        for _, row in top_df.iterrows():
            item = {
                "experience_id": str(row.get("experience_id", "")),
                "experience_name": str(row.get("experience_name", "")),
                "city": str(row.get("city", "")),
                "district": str(row.get("district", "")) if pd.notna(row.get("district")) else None,
                "state": str(row.get("state", "")) if pd.notna(row.get("state")) else None,
                "category": str(row.get("category", "")),
                "sub_category": str(row.get("sub_category", "")),
                "description": str(row.get("description", "")) if pd.notna(row.get("description")) else "",
                "tags": str(row.get("tags", "")) if pd.notna(row.get("tags")) else "",
                "best_for": str(row.get("best_for", "")) if pd.notna(row.get("best_for")) else "",
                "price_inr": float(row.get("price_inr_clean", row.get("price_inr", 0.0))),
                "duration_hours": float(row.get("duration_hours_clean", row.get("duration_hours", 0.0))),
                "rating": float(row.get("rating")) if pd.notna(row.get("rating")) else None,
                "review_count": int(row.get("review_count")) if pd.notna(row.get("review_count")) else None,
                "latitude": float(row.get("latitude")) if pd.notna(row.get("latitude")) else None,
                "longitude": float(row.get("longitude")) if pd.notna(row.get("longitude")) else None,
                "indoor_outdoor": str(row.get("indoor_outdoor_clean", row.get("indoor_outdoor", "Flexible"))),
                "local_experience": bool(row.get("local_experience_bool", False)),
                "hidden_gem": bool(row.get("hidden_gem_bool", False)),
                "distance_km": float(np.round(row["distance_km"], 2)) if pd.notna(row.get("distance_km")) else None,
                "recommendation_score": float(row["recommendation_score"]),
                "interest_overlap_count": int(row["interest_overlap_count"]),
                "interest_overlap_ratio": float(row["interest_overlap_ratio"]),
            }
            results.append(item)

        return results
