"""
LocalLens Backend Application Entrypoint.
Intelligent Discovery, ML Recommendation, and Itinerary Generation Service.
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
try:
    from backend.app.core.config import settings
    from backend.app.api.recommendations.recommendation_routes import router as recommendation_router
    from backend.app.api.itinerary.itinerary_routes import router as itinerary_router
except ImportError:
    from app.core.config import settings
    from app.api.recommendations.recommendation_routes import router as recommendation_router
    from app.api.itinerary.itinerary_routes import router as itinerary_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.ENVIRONMENT == "development" else settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint for container probes and service verification.
    """
    return {"status": "ok"}
