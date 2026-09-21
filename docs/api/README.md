# LocalLens API Design & Specifications

The backend exposes a RESTful API organized by domain namespaces.

## API Endpoint Blueprint

| Domain Area | Route Prefix | Description |
| :--- | :--- | :--- |
| **Health** | `GET /health` | Liveness & readiness probe |
| **Traveler** | `/api/v1/traveler` | User profile, preferences, and saved plans |
| **Provider** | `/api/v1/provider` | Host experience management and verification |
| **Rider** | `/api/v1/rider` | Driver dispatch, status, and earnings |
| **Experiences** | `/api/v1/experiences` | Catalog discovery, geo-filtering, reviews |
| **Itinerary** | `/api/v1/itinerary` | Automated itinerary synthesis and re-routing |
| **Rides** | `/api/v1/rides` | Ride request matching and tracking |
| **Recommendations** | `/api/v1/recommendations` | Contextual recommendation feeds |
| **Notifications** | `/api/v1/notifications` | Alert dispatch and event streaming |

## Interactive Documentation

When the backend server is running:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/api/v1/openapi.json`
