# 🎵 MusicGraph

**Explore music collaborations using Neo4j graph database and MusicBrainz API.**

A full-stack web application showcasing artist relationships, recordings, and collaborations in a modern, interactive interface.

---

## ✨ Features

- 🔍 **Search & Import** — Find artists on MusicBrainz and import them to your personal graph
- 📊 **Collaboration Detection** — Automatically discover who works together
- 🎼 **Recording Tracking** — View all recordings and see featured collaborations
- 🤝 **Relationship Mapping** — Explore who collaborated on which tracks
- 📈 **Statistics** — Database insights and analytics
- 🎨 **Modern UI** — Beautiful, responsive design (mobile to desktop)
- ⚡ **Real-time Data** — Neo4j graph queries with instant results

---

## 🏗️ Architecture

```
                    Frontend (React 18)
                     http://localhost:3000
                            ↓
                     REST API (FastAPI)
                     http://localhost:8000
                            ↓
                    Neo4j Graph Database
                     http://localhost:7687
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | React 18 + Vite | Modern SPA with HMR |
| **Backend** | FastAPI (Python) | High-performance API |
| **Database** | Neo4j 5.12 | Graph database for relationships |
| **External API** | MusicBrainz | Artist & recording metadata |
| **Orchestration** | Docker Compose | Local & deployment setup |

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)

### 30-Second Setup

```bash
docker compose up --build
```

Then open **http://localhost:3000** in your browser.

### Services

| Service | URL | Port | Status |
|---------|-----|------|--------|
| Frontend | http://localhost:3000 | 3000 | ✅ |
| Backend API | http://localhost:8000 | 8000 | ✅ |
| Neo4j Browser | http://localhost:7474 | 7474 | ✅ |

---

## 📖 Documentation

### Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** — Fast 30-second setup guide
- **[INSTALLATION.md](INSTALLATION.md)** — Detailed installation instructions

### Developer Guides
- **[FRONTEND_README.md](FRONTEND_README.md)** — Frontend architecture & development
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** — Full API reference
- **[docs/design.md](docs/design.md)** — System architecture & data model
- **[docs/oral_presentation.md](docs/oral_presentation.md)** — Implementation details by part
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Common issues & solutions

### Project Context
- **[claude.md](claude.md)** — Project objectives & scope
- **[PART5_ROADMAP.md](PART5_ROADMAP.md)** — Development roadmap

---

## 🎯 Workflow

### 1. Search for Artists

```
Frontend → Search "Daft Punk" → MusicBrainz API → Results
```

### 2. Import to Database

```
Click "Import" → API creates Artist node → Neo4j stores data
```

### 3. Explore Details

```
Click artist → View recordings → See collaborators → Navigate relationships
```

---

## 🔌 API Endpoints

All endpoints under `http://localhost:8000/api/`

### Artists
- `GET /artists` — List all artists
- `GET /artists/{mbid}` — Get artist details (with recordings & collaborators)
- `GET /artists/{mbid}/collaborations` — List collaborators
- `GET /search/artists?q=query` — Search MusicBrainz

### Management
- `POST /import/artists` — Import artist to Neo4j
- `POST /enrich/artists` — Fetch recordings & detect collaborations
- `GET /graph/{mbid}` — Get full graph around artist

### System
- `GET /health` — Backend health check

**Full API documentation:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

---

## 📂 Project Structure

```
musicgraph/
├── frontend/                  # React 18 + Vite SPA
│   ├── src/
│   │   ├── pages/             # 5 page components
│   │   ├── components/        # Reusable components
│   │   ├── api.js             # API client
│   │   └── index.css          # Global styles
│   ├── package.json
│   └── vite.config.js
│
├── backend/                   # FastAPI application
│   ├── app/
│   │   ├── main.py            # API endpoints (7)
│   │   ├── neo4j_client.py    # Database client (10+ functions)
│   │   └── musicbrainz_mock.py # Mock data fallback
│   ├── requirements.txt
│   └── Dockerfile
│
├── docs/                      # Documentation
│   ├── design.md              # Architecture & design
│   └── oral_presentation.md   # Implementation details
│
├── docker-compose.yml         # Services orchestration
├── .env.example               # Environment template
└── README.md                  # This file
```

---

## 💻 Development

### Local Development (Frontend)

```bash
cd frontend
npm install
npm run dev
```

Starts at http://localhost:5173 with hot module reloading.

### Local Development (Backend)

```bash
# Start Neo4j and backend
docker compose up neo4j backend
```

Backend runs on http://localhost:8000 with auto-reload.

### Production Build

```bash
# Build frontend
cd frontend && npm run build

# Docker production setup
docker compose -f docker-compose.yml up --build
```

---

## 🧪 Testing

### Full Stack Test

```bash
# Start all services
docker compose up --build

# Wait for startup (30 seconds)
# Open http://localhost:3000

# Try this workflow:
# 1. Search "Daft Punk"
# 2. Click "Import & Explore"
# 3. View recordings and collaborators
# 4. Click a collaborator to navigate
```

### API Test

```bash
# Health check
curl http://localhost:8000/api/health

# Search artists
curl "http://localhost:8000/api/search/artists?q=Daft%20Punk"

# Get all artists
curl http://localhost:8000/api/artists
```

---

## 📊 Database Schema

### Nodes
- **Artist** — Musicians/bands (MBID, name, country, type, dates)
- **Recording** — Songs/tracks (MBID, name, length)
- **Release** — Albums/EPs (MBID, name, date, type)

### Relationships
- `PERFORMED` — Artist recorded this track
- `FEATURED_ON` — Artist featured on track
- `COLLABORATED_WITH` — Artists worked together (bidirectional)
- `APPEARS_ON` — Recording is on this release

### Example Query

```cypher
MATCH (a1:Artist)-[:PERFORMED]->(:Recording)<-[:PERFORMED]-(a2:Artist)
WHERE a1.mbid = "056e4f3e-d505-4dad-8ec1-d04f521cbb56"
RETURN DISTINCT a2.name, COUNT(*) as collaborations
ORDER BY collaborations DESC
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` from `.env.example`:

```env
# Neo4j
NEO4J_URI=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=change-me

# MusicBrainz API
MUSICBRAINZ_USER_AGENT=MusicGraph/1.0 (your-email@example.com)

# Frontend
VITE_API_BASE=http://localhost:8000/api
```

---

## 📈 Project Progress

| Part | Component | Status |
|------|-----------|--------|
| 1 | Analysis & Design | ✅ 100% |
| 2 | Backend & Import (MusicBrainz) | ✅ 100% |
| 3 | Relations & Collaborations | ✅ 100% |
| 4 | API Endpoints (Neo4j Queries) | ✅ 100% |
| 5 | Frontend & Visualization | ✅ 100% |
| 6 | Docker, Data & Documentation | ✅ 100% |

**Overall: 100% Complete (6/6 Parts)** ✅

---

## 🎓 Learning Outcomes

This project demonstrates:

- ✅ **Full-stack web development** (frontend + backend + database)
- ✅ **Graph databases** (Neo4j, Cypher, relationship modeling)
- ✅ **REST API design** (FastAPI, endpoints, error handling)
- ✅ **Modern frontend** (React, components, routing, API integration)
- ✅ **Containerization** (Docker, Docker Compose, multi-container apps)
- ✅ **Data integration** (third-party API consumption)
- ✅ **Responsive design** (mobile-first CSS, Vite bundling)

---

## 🚨 Troubleshooting

### Port Already in Use
```bash
# Change port in docker-compose.yml:
# ports: [‘3001:3000’]
```

### Neo4j Connection Refused
```bash
# Wait for Neo4j to fully start (~15 seconds)
docker compose logs neo4j
```

### Frontend Can’t Reach API
```bash
# Check backend is running
curl http://localhost:8000/api/health
```

**More help:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📄 License

Educational project. Free to use and modify.

---

## 👤 Author

Created as part of a NoSQL & Graph Database learning exercise.

**Status:** Complete & Production-Ready ✅

---

## 🎯 Quick Links

- 🚀 [Quick Start](QUICKSTART.md) — 30-second setup
- 📖 [Installation Guide](INSTALLATION.md) — Detailed setup
- 🔌 [API Reference](API_DOCUMENTATION.md) — All endpoints
- 🎨 [Frontend Guide](FRONTEND_README.md) — React development
- 🗺️ [Roadmap](PART5_ROADMAP.md) — Development plan

---

**Ready to start?** Run `docker compose up --build` and open http://localhost:3000 🎵
