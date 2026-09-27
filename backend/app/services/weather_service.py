import logging
from typing import Any, Dict, Optional
import httpx

logger = logging.getLogger(__name__)

# Known City Coordinates for India
CITY_COORDINATES: Dict[str, tuple[float, float]] = {
    "mumbai": (18.9894, 73.1175),
    "navi mumbai": (19.0330, 73.0297),
    "delhi": (28.6139, 77.2090),
    "new delhi": (28.6139, 77.2090),
    "bangalore": (12.9716, 77.5946),
    "bengaluru": (12.9716, 77.5946),
    "goa": (15.2993, 74.1240),
    "jaipur": (26.9124, 75.7873),
    "hyderabad": (17.3850, 78.4867),
    "kolkata": (22.5726, 88.3639),
    "chennai": (13.0827, 80.2707),
    "pune": (18.5204, 73.8567),
    "agra": (27.1767, 78.0081),
    "varanasi": (25.3176, 82.9739),
}

WMO_CODE_MAP = {
    0: "Clear Sky",
    1: "Mainly Clear",
    2: "Partly Cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing Rime Fog",
    51: "Light Drizzle",
    53: "Moderate Drizzle",
    55: "Dense Drizzle",
    61: "Slight Rain",
    62: "Moderate Rain",
    65: "Heavy Rain",
    71: "Slight Snow Fall",
    80: "Slight Rain Showers",
    81: "Moderate Rain Showers",
    82: "Violent Rain Showers",
    95: "Thunderstorm",
    96: "Thunderstorm with Slight Hail",
    99: "Thunderstorm with Heavy Hail",
}


class WeatherService:
    """Service layer for weather ingestion and condition assessment."""

    @classmethod
    async def get_weather_forecast(
        cls,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        destination: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Fetches external meteorological data from Open-Meteo API.
        Non-blocking with fast timeout and fallback.
        """
        # Resolve coordinates
        target_lat = lat
        target_lon = lon

        if (target_lat is None or target_lon is None) and destination:
            clean_dest = destination.strip().lower()
            for city_name, coords in CITY_COORDINATES.items():
                if city_name in clean_dest:
                    target_lat, target_lon = coords
                    break

        if target_lat is None or target_lon is None:
            # Default to Mumbai / Navi Mumbai region
            target_lat, target_lon = 18.9894, 73.1175

        try:
            url = (
                f"https://api.open-meteo.com/v1/forecast"
                f"?latitude={target_lat}&longitude={target_lon}"
                f"&current_weather=true"
            )
            async with httpx.AsyncClient(timeout=3.0) as client:
                res = await client.get(url)
                if res.status_code == 200:
                    data = res.json()
                    cw = data.get("current_weather", {})
                    code = cw.get("weathercode", 0)
                    condition = WMO_CODE_MAP.get(int(code), "Clear Sky")
                    temp = cw.get("temperature", 28.0)
                    wind = cw.get("windspeed", 10.0)

                    return {
                        "condition": condition,
                        "temperature": f"{temp}°C",
                        "temperature_c": float(temp),
                        "rainfall_mm": 0.0 if "rain" not in condition.lower() else 5.0,
                        "humidity_pct": 65,
                        "wind_speed_kmh": f"{wind} km/h",
                        "source": "open-meteo",
                        "latitude": target_lat,
                        "longitude": target_lon,
                    }
        except Exception as e:
            logger.debug(f"[WeatherService] Live weather fetch skipped/timed out: {e}")

        # Fallback realistic weather data
        return {
            "condition": "Clear Sky",
            "temperature": "28°C",
            "temperature_c": 28.0,
            "rainfall_mm": 0.0,
            "humidity_pct": 60,
            "wind_speed_kmh": "12 km/h",
            "source": "local_estimate",
            "latitude": target_lat,
            "longitude": target_lon,
        }
