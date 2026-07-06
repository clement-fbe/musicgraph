# MusicGraph — Quick Start Guide

## 🚀 Start in 30 seconds

### Option 1: Docker (Recommended)
```bash
cd c:\Users\codcl\Documents\B+3Ynov\NoSQL
docker compose up --build
```

Then open: **http://localhost:3000**

### Option 2: Local Development
```bash
# Terminal 1: Frontend dev server
cd frontend
npm install
npm run dev
# Opens at http://localhost:5173

# Terminal 2: Backend + Neo4j
cd ..
docker compose up neo4j backend
```

---

## ✨ What You Get

### Frontend (React 18)
- Search for any artist on MusicBrainz
- One-click import to Neo4j
- View recordings and collaborators
- Responsive design (mobile/desktop)
- Beautiful UI with gradients

### Backend (FastAPI)
- 7 REST endpoints
- MusicBrainz integration
- Neo4j graph database
- Retry logic + error handling

### Database (Neo4j)
- Artist nodes
- Recording relationships
- Collaboration networks
- Real-time graph queries

---

## 🎯 Try This Workflow

1. **Search** → Type "Daft Punk"
2. **Import** → Click "Import & Explore"
3. **Explore** → View recordings and collaborators
4. **Navigate** → Click a collaborator to dive deeper

---

## 📖 Full Documentation

- **FRONTEND_README.md** — Frontend guide
- **PART5_ROADMAP.md** — Next steps
- **docs/design.md** — Architecture
- **docs/oral_presentation.md** — Implementation details

---

## 🔧 Common Commands

```bash
# Start everything
docker compose up --build

# Stop everything
docker compose down

# View logs
docker compose logs -f backend

# Frontend development only
cd frontend && npm run dev

# Build frontend for production
cd frontend && npm run build
```

---

## 🌐 Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:3000 | Web app |
| Backend | http://localhost:8000 | API |
| Neo4j | http://localhost:7474 | Database UI |

---

## ✅ Status

- **Part 1-4:** 100% Complete ✅
- **Part 5:** Ready (documentation only) ⏳

Project is **fully functional** and ready to use!

---

**Questions?** Check PART5_ROADMAP.md or docs/ folder for detailed guides.
