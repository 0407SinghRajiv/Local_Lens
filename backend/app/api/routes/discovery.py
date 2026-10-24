"""
Weather-Smart Discovery Canvas API Endpoints.
Categorizes, ranks, and grounds places using ML scores and meteorological context.
"""
from fastapi import APIRouter
from backend.app.schemas.discovery_schemas import DiscoveryRequest, DiscoveryResponse
from backend.app.services.discovery_service import DiscoveryService

router = APIRouter(prefix="/discovery", tags=["Discovery"])


@router.post("/recommendations", response_model=DiscoveryResponse)
async def get_discovery_recommendations(request: DiscoveryRequest):
    """
    Returns categorized discovery recommendations (Food, Culture, Adventure, Nature, Indoor, Shopping)
    adapted to the trip destination and real weather forecast.
    """
    return await DiscoveryService.get_discovery_canvas(request)
