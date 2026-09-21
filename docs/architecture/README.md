# LocalLens Architecture Overview

LocalLens is designed as a modular platform with clean boundaries between frontend experiences, backend API services, spatial data persistence, and machine learning pipelines.

## High-Level Topology

```text
               +----------------------------------+
               |        Next.js Frontend          |
               | (Traveler, Provider, Discovery)  |
               +----------------+-----------------+
                                |
                         HTTP / REST & WS
                                |
               +----------------v-----------------+
               |         FastAPI Backend          |
               | (Routing, Auth, Dispatch, Svc)   |
               +--------+-------+--------+--------+
                        |       |        |
         +--------------+       |        +---------------+
         |                      |                        |
         v                      v                        v
+------------------+  +-------------------+  +---------------------+
| PostgreSQL/GIS   |  |   Redis Cache     |  | ML Inference Engine |
| Spatial Data &   |  |   & Real-time     |  | (Recommendations &  |
| Relational Model |  |   Event Broker    |  |  Itinerary Solver)  |
+------------------+  +-------------------+  +---------------------+
```

## System Responsibilities

### 1. Frontend (`frontend/`)
- Client interfaces using Next.js App Router, React, TypeScript, and Tailwind CSS.
- Feature boundaries separated by user personas (`features/traveler`, `features/provider`, `features/rider`).

### 2. Backend (`backend/`)
- High-performance asynchronous API engine powered by FastAPI.
- Layered pattern: API Router → Service Layer → Repository Layer → Database Engine.

### 3. Spatial Database (`database/`)
- PostgreSQL with PostGIS extensions for spatial indexing (`GEOMETRY`), radius querying, and itinerary location ordering.

### 4. Real-time Broker (`Redis`)
- Transient state management, WebSocket subscription hubs, and driver telemetry caching.

### 5. Machine Learning Pipelines (`ml/`)
- Preference-based recommendation modeling, route & itinerary constraint optimization, and experience listing quality verification.
