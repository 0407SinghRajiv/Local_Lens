# LocalLens

LocalLens is an intelligent local discovery and experience platform that helps travelers discover relevant local experiences, generate personalized itineraries, manage rides, and adapt plans when real-world conditions change.

## Tech Stack

- **Frontend**: Next.js, React, TypeScript, Tailwind CSS
- **Backend**: FastAPI, Python, SQLAlchemy, Pydantic
- **Database**: PostgreSQL + PostGIS
- **ML**: Scikit-learn, XGBoost, Transformers, PyTorch
- **Realtime**: Redis + WebSockets
- **Infrastructure**: Docker & Docker Compose

## Project Structure

```text
LocalLens/
│
├── frontend/          # Next.js (App Router, TypeScript, Tailwind CSS)
├── backend/           # FastAPI service, routers, repositories, models
├── ml/                # Machine learning exploration, models, pipelines
├── database/          # PostgreSQL + PostGIS schemas, migrations, seeds
├── rider-app/         # Rider mobile/web app workspace & documentation
├── docs/              # Technical, architectural, API & setup documentation
│
├── .gitignore         # Monorepo gitignore rules
├── .env.example       # Template environment variables
├── docker-compose.yml # PostgreSQL + PostGIS & Redis container configurations
├── README.md          # Project overview and instructions
└── LICENSE            # MIT License
```

## Local Setup

### 1. Prerequisites
- [Docker](https://www.docker.com/) and Docker Compose
- [Node.js](https://nodejs.org/) (v18+ or v20+) and `npm`
- [Python](https://www.python.org/) (v3.10+)

### 2. Start Database & Redis
```bash
docker compose up -d
```

### 3. Frontend Setup
```bash
cd frontend
npm install
npm run dev
```
The frontend will be available at `http://localhost:3000`.

### 4. Backend Setup
```bash
cd backend
python -m venv venv
```

**Windows activation:**
```powershell
venv\Scripts\activate
```

**Linux/macOS activation:**
```bash
source venv/bin/activate
```

**Install dependencies & run:**
```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```
The backend API documentation will be available at `http://localhost:8000/docs`.

### 5. ML Workspace Setup
```bash
cd ml
python -m venv venv

# Windows
venv\Scripts\activate
# Linux/macOS
# source venv/bin/activate

pip install -r requirements.txt
```

## Health Check

To verify the backend service is running:

```http
GET /health
```

**Response:**
```json
{
  "status": "ok"
}
```

## Team Development

To keep work organized across independent developers, follow feature branching conventions:

- `feature/traveler` - Traveler discovery, booking, and itinerary UI/workflows
- `feature/provider` - Experience host/provider onboarding and experience management
- `feature/rider` - Rider dispatch, geolocation tracking, and ride status updates
- `feature/backend` - Core API routes, services, schemas, and database repositories
- `feature/recommendation` - Recommendation engine algorithms and scoring models
- `feature/itinerary` - Dynamic itinerary generation and constraint optimization
- `feature/database` - Migrations, PostGIS spatial queries, and schema evolution
