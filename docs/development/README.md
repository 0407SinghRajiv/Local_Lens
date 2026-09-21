# LocalLens Developer Guide

Guidelines for setting up, running, and contributing to the LocalLens repository.

## 1. Prerequisites

- **Docker Desktop** (or Docker Engine with Compose v2)
- **Node.js** (v18+ or v20+) & **npm**
- **Python** (v3.10+ / v3.11+)

---

## 2. Starting Infrastructure Services

Start the PostgreSQL + PostGIS database and Redis cache:

```bash
docker compose up -d
```

Verify service health:
```bash
docker compose ps
```

---

## 3. Running the Backend

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate on Windows:
venv\Scripts\activate
# Activate on macOS/Linux:
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start FastAPI dev server
uvicorn app.main:app --reload --port 8000
```

Verify health check:
```bash
curl http://localhost:8000/health
```

---

## 4. Running the Frontend

```bash
cd frontend

# Install packages
npm install

# Start Next.js development server
npm run dev
```

Visit `http://localhost:3000`.

---

## 5. Running the ML Environment

```bash
cd ml

# Create virtual environment
python -m venv venv

# Activate
# Windows: venv\Scripts\activate
# Linux/macOS: source venv/bin/activate

# Install ML packages
pip install -r requirements.txt
```

---

## 6. Git Branching & Collaboration

To enable multi-developer parallelism without conflicts, branch off `main` using standard naming:

| Prefix | Domain Scope |
| :--- | :--- |
| `feature/traveler` | Traveler discovery, preferences, booking UI |
| `feature/provider` | Provider experience management, hosting UI |
| `feature/rider` | Rider tracking and dispatch services |
| `feature/backend` | API endpoints, repositories, database models |
| `feature/recommendation` | Recommendation model development |
| `feature/itinerary` | Itinerary optimization engine |
| `feature/database` | Database schemas and migrations |
