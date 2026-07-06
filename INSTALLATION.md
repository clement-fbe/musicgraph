# Installation Guide — MusicGraph

Complete step-by-step guide to set up MusicGraph locally.

---

## Prerequisites

### Required
- **Docker** (version 20.10+) — [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (version 2.0+) — Usually comes with Docker Desktop
- **Git** (optional but recommended)

### For Local Development Only
- **Node.js** 18+ — [Install Node.js](https://nodejs.org/)
- **Python** 3.12+ — [Install Python](https://www.python.org/)

---

## Option 1: Docker (Recommended — 5 minutes)

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd musicgraph
```

Or download the ZIP file and extract it.

### Step 2: Start Services

```bash
docker compose up --build
```

**Wait for startup messages:**
- Neo4j: `"Started"`
- Backend: `"Uvicorn running on http://0.0.0.0:8000"`
- Frontend: `"ready in X ms"`

Typically takes 30-45 seconds.

### Step 3: Access Application

Open your browser:
- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8000/api/health
- **Neo4j Browser:** http://localhost:7474

### Done! ✅

You're ready to use the application.

---

## Option 2: Local Development (10 minutes)

For development with hot reloading.

### Step 1: Start Docker Services

```bash
docker compose up neo4j backend
```

Wait for Neo4j and Backend to be ready (30 seconds).

### Step 2: Start Frontend (New Terminal)

```bash
cd frontend
npm install
npm run dev
```

Frontend starts at **http://localhost:5173**

### Step 3: Access Application

- **Frontend (Dev):** http://localhost:5173
- **Backend API:** http://localhost:8000
- **Neo4j Browser:** http://localhost:7474

### Benefits

- ✅ Hot Module Reloading (HMR) on code changes
- ✅ Faster development iteration
- ✅ Full backend + database still in Docker

---

## Configuration

### .env File

Create `.env` from `.env.example`:

```bash
cp .env.example .env
```

Edit `.env` if needed (optional — defaults work for local development):

```env
# Neo4j connection
NEO4J_URI=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=change-me

# MusicBrainz API
MUSICBRAINZ_USER_AGENT=MusicGraph/1.0 (your-email@example.com)

# Frontend API base (only for production builds)
VITE_API_BASE=http://localhost:8000/api
```

---

## Verification

### Check All Services

```bash
docker compose ps
```

Should show all 3 containers as `UP`:

```
NAME                 STATUS
musicgraph-neo4j     Up 1 minute
musicgraph-backend   Up 50 seconds
musicgraph-frontend  Up 30 seconds
```

### Test Backend

```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{"status":"ok"}
```

### Test Neo4j

Browser at http://localhost:7474

Login:
- Username: `neo4j`
- Password: `change-me`

---

## Troubleshooting

### Port Already in Use

**Error:** `bind: address already in use`

**Solution:** Find and stop the process, or change the port

```bash
# Windows
netstat -ano | findstr :3000

# Linux/Mac
lsof -i :3000

# Change port in docker-compose.yml
# Change "3000:3000" to "3001:3000"
```

Then restart:

```bash
docker compose restart
```

### Docker Daemon Not Running

**Error:** `Cannot connect to Docker daemon`

**Solution:** Start Docker Desktop (Windows/Mac) or Docker service (Linux)

```bash
# Linux
sudo systemctl start docker
```

### Slow Performance

**Solution:** Increase Docker resources

Docker Desktop → Settings → Resources:
- CPUs: 4+
- Memory: 4GB+

### Neo4j Password Error

**Error:** `Authorization failed: 'neo4j' is not a valid user`

**Solution:** Reset Neo4j data

```bash
docker compose down
docker volume rm musicgraph_neo4j_data  # or your volume name
docker compose up --build
```

### Frontend API Errors

**Error:** `Cannot reach http://localhost:8000`

**Solution:** 
1. Check backend is running: `curl http://localhost:8000/api/health`
2. Check Vite proxy in `frontend/vite.config.js`

---

## Uninstall

### Remove All Containers & Data

```bash
# Stop all services
docker compose down

# Remove volumes (persistent data)
docker compose down -v

# Clean up images (optional)
docker rmi musicgraph_frontend musicgraph_backend
```

### Keep Data, Just Stop Services

```bash
docker compose stop
```

### Resume Later

```bash
docker compose up
```

---

## Network Issues

### MusicBrainz API Timeout

**Error:** `Falling back to mock data...`

**Reason:** Network connectivity to MusicBrainz

**Solution:**
- Check internet connection
- Try again later
- Use mock data (fallback enabled)

### Health Check Failure

```bash
# View logs
docker compose logs -f backend

# Check all services
docker compose logs
```

---

## Production Deployment

For production deployments, see [PART5_ROADMAP.md](PART5_ROADMAP.md).

Key steps:
1. Update `.env` with production credentials
2. Change Neo4j password from `change-me`
3. Use production Docker registry
4. Enable HTTPS
5. Set up reverse proxy (nginx)

---

## Advanced Options

### Build Frontend Only

```bash
cd frontend
npm run build
npm run preview  # Preview production build locally
```

### Run Backend in Debug Mode

```bash
docker compose exec backend bash
python -m pdb app/main.py
```

### Access Neo4j CLI

```bash
docker compose exec neo4j cypher-shell
# Login: neo4j / change-me
```

---

## Support

If you encounter issues:

1. **Check logs:**
   ```bash
   docker compose logs <service-name>
   ```

2. **See troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

3. **Check documentation:** [README.md](README.md)

---

## Next Steps

After installation:

1. Open http://localhost:3000
2. Try searching for "Daft Punk"
3. Click "Import & Explore"
4. View the artist's recordings and collaborators
5. Click on collaborators to explore relationships

**Happy exploring! 🎵**
