# LocalLens Machine Learning Workspace

This workspace hosts the data preprocessing, model training, evaluation, and inference pipelines for LocalLens intelligent discovery engines.

## Workspace Structure

```text
ml/
├── models/               # Saved model weights, checkpoints, and serialization artifacts (ignored by git)
├── datasets/             # Raw, processed, and synthetic dataset splits
├── notebooks/            # Jupyter exploratory analysis and experimentation notebooks
├── preprocessing/        # Feature extraction, text cleaning, geospatial tokenization
├── recommendation/       # Recommendation Engine: Traveler preferences → Experience recommendations
├── itinerary/            # Itinerary Engine: Experiences + time + budget + distance → Optimized plan
├── experience_quality/   # Experience Quality Engine: Provider experience info → Quality validation
├── inference/            # Model serving adapters, runtime inference interfaces
├── tests/                # Unit & integration tests for ML pipelines
├── requirements.txt      # Python dependencies for ML
├── .env.example          # ML workspace configuration template
└── README.md
```

## Core ML Components

### 1. Recommendation Engine (`ml/recommendation/`)
- **Objective**: Match traveler preferences, historical engagement, and real-time contextual signals to high-affinity local experiences.
- **Approaches**: Collaborative filtering, vector similarity search, and hybrid ranking models.

### 2. Itinerary Engine (`ml/itinerary/`)
- **Objective**: Synthesize candidate experiences into time-, budget-, and distance-optimal day schedules.
- **Approaches**: Operations research / constraint optimization, genetic algorithms, and reinforcement learning.

### 3. Experience Quality Engine (`ml/experience_quality/`)
- **Objective**: Assess provider listings for completeness, authentic descriptions, pricing fairness, and anomaly detection.
- **Approaches**: NLP classification, text embeddings, and automated listing quality scoring.

## Getting Started

### 1. Virtual Environment Setup
```bash
cd ml
python -m venv venv
```

**Activate (Windows):**
```powershell
venv\Scripts\activate
```

**Activate (macOS/Linux):**
```bash
source venv/bin/activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```
