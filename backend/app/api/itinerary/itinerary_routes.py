"""
Itinerary API Endpoints.
Exposes POST /api/itinerary/generate to synthesize chronological itineraries from selected experiences.
"""
from fastapi import APIRouter, HTTPException, status
try:
    from app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
        ItineraryChatOptimizeRequest,
        ItineraryChatOptimizeResponse,
    )
    from app.services.itinerary_service import ItineraryService
    from app.services.nugen_service import NugenService
    from app.core.config import settings
except ImportError:
    from backend.app.schemas.itinerary_schemas import (
        ItineraryGenerateRequest,
        ItineraryGenerateResponse,
        ItineraryChatOptimizeRequest,
        ItineraryChatOptimizeResponse,
    )
    from backend.app.services.itinerary_service import ItineraryService
    from backend.app.services.nugen_service import NugenService
    from backend.app.core.config import settings
import json
import httpx
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
        # Rajiv's ML system generates the primary authoritative itinerary
        response = ItineraryService.generate_itinerary(request)

        # Nugen AI Enhancement + Validation Layer (Runs strictly AFTER generation)
        if getattr(settings, "NUGEN_ENABLED", False):
            try:
                user_constraints = {
                    "budget": request.budget_inr or request.budget,
                    "available_time_hours": request.available_time_hours or request.duration_hours,
                    "traveler_count": request.traveler_count,
                    "group_type": request.group_type or request.traveler_type,
                    "interests": getattr(request, "interests", []),
                    "selected_places": request.selected_experience_ids,
                    "destination": request.destination,
                }
                nugen_insights = await NugenService.enhance_itinerary(
                    user_constraints=user_constraints,
                    generated_itinerary=response.model_dump(),
                )
                if nugen_insights:
                    response.nugen = nugen_insights
            except Exception as nugen_err:
                logger.error(f"[NUGEN] Non-critical enhancement error: {nugen_err}", exc_info=True)

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

        # Nugen AI Enhancement + Validation Layer (Runs strictly AFTER optimization)
        if getattr(settings, "NUGEN_ENABLED", False):
            try:
                user_constraints = {
                    "budget": request.budget_inr or request.budget,
                    "available_time_hours": request.available_time_hours or request.duration_hours,
                    "traveler_count": request.traveler_count,
                    "group_type": request.group_type or request.traveler_type,
                    "interests": getattr(request, "interests", []),
                    "selected_places": request.selected_experience_ids,
                    "destination": request.destination,
                }
                nugen_insights = await NugenService.enhance_itinerary(
                    user_constraints=user_constraints,
                    generated_itinerary=response.model_dump(),
                )
                if nugen_insights:
                    response.nugen = nugen_insights
            except Exception as nugen_err:
                logger.error(f"[NUGEN] Non-critical enhancement error in optimize: {nugen_err}", exc_info=True)

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


@router.post("/optimize/chat", response_model=ItineraryChatOptimizeResponse)
@router.post("/optimize/chat/", response_model=ItineraryChatOptimizeResponse, include_in_schema=False)
async def optimize_itinerary_chat(request: ItineraryChatOptimizeRequest):
    """
    Conversational Itinerary Optimization using Groq AI.
    Parses traveler intents (e.g., swapping food with beaches, budget changes, route optimization)
    and returns structured preference modifications.
    """
    prompt = request.prompt.strip()
    if not prompt:
        return ItineraryChatOptimizeResponse(
            reply="Please tell me how you would like to adjust your itinerary!",
        )

    groq_api_key = getattr(settings, "GROQ_API_KEY", "") or getattr(settings, "LLM_API_KEY", "")

    system_prompt = f"""You are LocalLens AI Itinerary Optimizer Assistant.
The traveler wants changes/optimizations to their itinerary.
Current Trip State:
- Destination: {request.destination}
- Current Interests: {', '.join(request.current_interests or [])}
- Stops: {', '.join(request.current_place_names or [])}
- Budget: ₹{request.budget}
- Duration: {request.duration_hours} hours

Recognized Categories in LocalLens:
Beach, Food, Culture, Adventure, Nature, Heritage, Shopping, Nightlife, Photography, Wellness, Hidden Gems, Local Experiences

Guidelines:
1. If traveler asks to replace/swap (e.g. "change food with beaches so generate it"):
   - remove_interests: ["Food"]
   - add_interests: ["Beach"]
   - should_regenerate: true
   - reply: Friendly confirmation that food spots will be replaced with beaches.
2. If traveler asks for route sequencing / fastest route only:
   - is_route_reorder_only: true
3. Return STRICTLY valid JSON object with keys:
   reply, remove_interests, add_interests, custom_notes, updated_budget, updated_duration_hours, should_regenerate, is_route_reorder_only.
"""

    models_to_try = ["openai/gpt-oss-120b", "openai/gpt-oss-20b"]

    for model in models_to_try:
        try:
            async with httpx.AsyncClient(timeout=12.0) as client:
                resp = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {groq_api_key}",
                        "Content-Type": "application/json",
                        "User-Agent": "LocalLens/1.0",
                    },
                    json={
                        "model": model,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": prompt},
                        ],
                        "response_format": {"type": "json_object"},
                        "temperature": 0.3,
                    },
                )
                if resp.status_code == 200:
                    data = resp.json()
                    content = data["choices"][0]["message"]["content"]
                    parsed = json.loads(content)
                    return ItineraryChatOptimizeResponse(
                        reply=parsed.get("reply", "Preferences updated successfully!"),
                        remove_interests=parsed.get("remove_interests") or [],
                        add_interests=parsed.get("add_interests") or [],
                        custom_notes=parsed.get("custom_notes"),
                        updated_budget=parsed.get("updated_budget"),
                        updated_duration_hours=parsed.get("updated_duration_hours"),
                        should_regenerate=bool(parsed.get("should_regenerate") or parsed.get("add_interests") or parsed.get("remove_interests")),
                        is_route_reorder_only=bool(parsed.get("is_route_reorder_only")),
                    )
        except Exception as e:
            logger.warning(f"[GroqChatOptimize] Model {model} attempt failed: {e}")

    # Fallback keyword logic
    lower = prompt.lower()
    remove_list = []
    add_list = []
    if "beach" in lower or "beaches" in lower:
        add_list.append("Beach")
    if "food" in lower and ("change" in lower or "replace" in lower or "remove" in lower):
        remove_list.append("Food")
    elif "food" in lower and not add_list:
        add_list.append("Food")

    is_reorder = "route" in lower or "order" in lower or "fastest" in lower

    reply = "I've updated your trip preferences based on your request. Ready to regenerate fresh recommendations!"
    if remove_list and add_list:
        reply = f"Swapped {', '.join(remove_list)} with {', '.join(add_list)}! Generating your refreshed recommendations."

    return ItineraryChatOptimizeResponse(
        reply=reply,
        remove_interests=remove_list,
        add_interests=add_list,
        custom_notes=prompt,
        should_regenerate=bool(remove_list or add_list or "generate" in lower),
        is_route_reorder_only=is_reorder,
    )
