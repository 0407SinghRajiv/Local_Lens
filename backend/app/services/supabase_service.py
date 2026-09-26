"""
Supabase Data Access & Synchronization Service.
Connects to Supabase experience table and provides real-time / cached experience records.
"""
from typing import Any, Dict, List, Optional, Tuple
import json
import logging
import os
import urllib.request
import urllib.error
import pandas as pd

logger = logging.getLogger(__name__)


class SupabaseService:
    """
    Manages communication with the Supabase experience table.
    """

    _cached_df: Optional[pd.DataFrame] = None

    @classmethod
    def get_credentials(cls) -> Tuple[str, str]:
        url = os.getenv("SUPABASE_URL", "https://mvokdnefwukzouuttsvz.supabase.co").strip()
        key = (
            os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            or os.getenv("SUPABASE_ANON_KEY")
            or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12b2tkbmVmd3Vrem91dXR0c3Z6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNTA1NzksImV4cCI6MjEwNTkyNjU3OX0.KsNjS6EP6hyw2-JZlKgvV3AdqpZudVGCI7guH0YE9w4"
        ).strip()
        return url, key

    @classmethod
    def fetch_experiences_from_supabase(cls) -> Optional[pd.DataFrame]:
        """
        Fetch all records from Supabase 'experience' table via REST API.
        """
        url, key = cls.get_credentials()
        if not url or not key:
            logger.warning("Supabase URL or Key not configured.")
            return None

        # Fetch using PostgREST endpoint
        endpoint = f"{url}/rest/v1/experience?select=*"
        headers = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Accept": "application/json",
        }

        try:
            req = urllib.request.Request(endpoint, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8"))
                    if data and len(data) > 0:
                        df = pd.DataFrame(data)
                        df = cls._normalize_supabase_dataframe(df)
                        cls._cached_df = df
                        logger.info(f"Successfully loaded {len(df)} experiences from Supabase.")
                        return df
                    else:
                        logger.info("Supabase experience table returned 0 rows.")
        except Exception as e:
            logger.warning(f"Failed to query Supabase experience table: {e}")

        return None

    @classmethod
    def _normalize_supabase_dataframe(cls, df: pd.DataFrame) -> pd.DataFrame:
        """
        Map and clean Supabase columns to match notebook feature names.
        """
        if "price_inr_clean" not in df.columns and "price_inr" in df.columns:
            df["price_inr_clean"] = pd.to_numeric(df["price_inr"], errors="coerce").fillna(0.0)
        elif "price_inr_clean" in df.columns:
            df["price_inr_clean"] = pd.to_numeric(df["price_inr_clean"], errors="coerce").fillna(0.0)

        if "duration_hours_clean" not in df.columns and "duration_hours" in df.columns:
            df["duration_hours_clean"] = pd.to_numeric(df["duration_hours"], errors="coerce").fillna(1.0)
        elif "duration_hours_clean" in df.columns:
            df["duration_hours_clean"] = pd.to_numeric(df["duration_hours_clean"], errors="coerce").fillna(1.0)

        if "rating_missing" not in df.columns:
            df["rating_missing"] = df["rating"].isna().astype(int)

        if "local_experience_bool" not in df.columns and "local_experience" in df.columns:
            df["local_experience_bool"] = df["local_experience"].fillna(True).astype(bool).astype(int)

        if "hidden_gem_bool" not in df.columns and "hidden_gem" in df.columns:
            df["hidden_gem_bool"] = df["hidden_gem"].fillna(False).astype(bool).astype(int)

        if "indoor_outdoor_clean" not in df.columns and "indoor_outdoor" in df.columns:
            df["indoor_outdoor_clean"] = df["indoor_outdoor"].fillna("Flexible")

        return df
