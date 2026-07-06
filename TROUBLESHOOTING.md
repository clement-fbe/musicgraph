# Troubleshooting Guide — MusicGraph

Common issues and solutions.

---

## Docker Issues

### "Cannot connect to Docker daemon"

**Cause:** Docker is not running

**Solution:**
1. Start Docker Desktop (Windows/Mac)
2. Or start Docker service (Linux):
   ```bash
   sudo systemctl start docker
   ```

### "Port already in use"

**Cause:** Another process is using the port

**Error message:**
```
bind: address already in use
```

**Solution 1: Find and stop the process**

Windows:
```bash
netstat -ano | findstr :3000  # Find process ID
taskkill /PID <PID> /F       # Kill the process
```

Linux/Mac:
```bash
lsof -i :3000                 # Find process
kill -9 <PID>                 # Kill the process
```

**Solution 2: Change the port**

Edit `docker-compose.yml`:
```yaml
frontend:
  ports:
    - '3001:3000'  # Changed from 3000:3000
```

Then restart:
```bash
docker compose restart
```

### "Cannot find image"

**Cause:** Image not built

**Solution:**
```bash
docker compose build --no-cache
docker compose up
```

### "Disk space error"

**Cause:** Docker ran out of disk space

**Solution:**
```bash
docker system prune -a
```

Warning: This removes all unused images.

---

## Neo4j Issues

### "Neo4j connection refused"

**Error:**
```
Couldn't connect to neo4j:7687 (resolved to ('172.20.0.2:7687',)):
Failed to establish connection
```

**Cause:** Neo4j hasn't fully started yet

**Solution:** Wait 30-45 seconds for Neo4j to start

Check logs:
```bash
docker compose logs neo4j
```

Look for:
```
Bolt enabled on 0.0.0.0:7687
```

### "Authorization failed"

**Error:**
```
Authorization failed: 'neo4j' is not a valid user
```

**Cause:** Password mismatch

**Solution:** Reset Neo4j

```bash
docker compose down
docker volume rm musicgraph_neo4j_data
docker compose up --build
```

### "Database locked"

**Cause:** Neo4j is busy

**Solution:** Restart Neo4j service

```bash
docker compose restart neo4j
```

### Cannot access Neo4j Browser

**Error:** 404 on http://localhost:7474

**Solution:**
1. Check Neo4j is running: `docker compose logs neo4j`
2. Wait for full startup (1-2 minutes)
3. Try again

---

## Backend Issues

### "Backend not responding"

**Error:**
```
Cannot GET http://localhost:8000/api/health
```

**Cause:** Backend service not running

**Solution:**
```bash
docker compose logs backend

# Check health
curl http://localhost:8000/api/health

# Restart
docker compose restart backend
```

### "ModuleNotFoundError"

**Cause:** Missing Python dependencies

**Solution:**
```bash
docker compose down
docker compose build --no-cache backend
docker compose up
```

### "MusicBrainz API timeout"

**Error:**
```
MusicBrainz API attempt 3/3 failed: ReadTimeout
Falling back to mock data
```

**Cause:** Network issues or slow API

**Solution:**
- Check internet connection
- Try again later
- Use mock data (fallback enabled)

### "CORS error"

**Frontend error:**
```
Access to XMLHttpRequest blocked by CORS policy
```

**Cause:** API proxy not working

**Solution:**
1. Check `frontend/vite.config.js` has proxy:
   ```javascript
   proxy: {
     '/api': {
       target: 'http://localhost:8000'
     }
   }
   ```

2. Restart frontend:
   ```bash
   docker compose restart frontend
   ```

---

## Frontend Issues

### "Cannot reach API"

**Error in browser console:**
```
Cannot GET http://localhost:3000/api/health
```

**Cause:** Frontend dev server not proxying correctly

**Solution:**
1. Check backend is running:
   ```bash
   curl http://localhost:8000/api/health
   ```

2. Check vite.config.js proxy

3. Restart:
   ```bash
   docker compose down
   docker compose up
   ```

### "Page is blank"

**Cause:** React not rendering

**Solution:**
1. Check browser console for errors
2. Check logs: `docker compose logs frontend`
3. Clear browser cache (Ctrl+Shift+Del)

### "API calls return 404"

**Cause:** Wrong API path

**Check:**
- Frontend making calls to `/api/...` (not `http://localhost:8000/api/...`)
- Vite proxy configured
- Backend running on port 8000

### "Slow page loads"

**Cause:** Large datasets or slow network

**Solution:**
- Check browser DevTools Network tab
- Restart services
- Check docker CPU/memory usage

---

## Data Issues

### "No artists in database"

**Cause:** Haven't imported any yet

**Solution:** Search and import an artist first

```bash
# Frontend: Search for "Daft Punk" → Import

# Or API:
curl -X POST http://localhost:8000/api/import/artists \
  -H "Content-Type: application/json" \
  -d '{"mbid":"056e4f3e-d505-4dad-8ec1-d04f521cbb56"}'
```

### "Duplicates in database"

**Cause:** Same artist imported twice

**Solution:** Neo4j MERGE pattern prevents this - shouldn't happen

If it does:
```bash
# Delete Neo4j data
docker compose down -v
docker compose up --build
```

### "Recording not linked to artist"

**Cause:** Recording not enriched

**Solution:** Enrich the artist

```bash
curl -X POST http://localhost:8000/api/enrich/artists \
  -H "Content-Type: application/json" \
  -d '{"mbid":"056e4f3e-d505-4dad-8ec1-d04f521cbb56", "fetch_recordings":true}'
```

---

## Performance Issues

### "Docker using too much memory"

**Solution:** Limit Docker resources

Docker Desktop Settings:
- CPUs: Set to number of cores - 1
- Memory: 4-8 GB
- Swap: 1-2 GB

### "Slow API responses"

**Cause:** Large datasets or slow queries

**Solution:**
1. Check Neo4j logs: `docker compose logs neo4j`
2. Limit results in Cypher queries
3. Increase Docker resources

### "Frontend building slowly"

**Cause:** Large dependencies or slow machine

**Solution:**
```bash
cd frontend

# Clear cache
rm -rf node_modules .vite

# Reinstall
npm install

# Run dev
npm run dev
```

---

## Network Issues

### "Cannot reach MusicBrainz"

**Error:**
```
Falling back to mock data...
```

**Cause:** No internet or API blocked

**Solution:**
- Check internet connection
- Check firewall
- Use VPN if blocked
- Use mock data (enabled by default)

### "DNS resolution failed"

**Error:**
```
Cannot resolve 'musicbrainz.org'
```

**Cause:** DNS issue

**Solution:**
```bash
# Restart Docker networking
docker compose down
docker compose up

# Or change Docker DNS
# Edit /etc/docker/daemon.json:
# "dns": ["8.8.8.8", "1.1.1.1"]
```

---

## Windows Specific

### WSL2 not installed

**Error:**
```
WSL 2 installation is incomplete
```

**Solution:**
1. Enable WSL2: Settings → Apps → Optional features
2. Install WSL2 update
3. Set WSL2 as default: `wsl --set-default-version 2`

### Path issues with volumes

**Error:**
```
C:\Users\...\path is not shareable
```

**Solution:**
1. Add path to Docker Desktop file sharing
2. Or move project to C:\Users directory

### Line endings (CRLF vs LF)

**Cause:** Git configured for Windows

**Solution:**
```bash
git config --global core.autocrlf input
```

---

## Mac Specific

### "Cannot connect to daemon socket"

**Cause:** Docker Desktop not running

**Solution:** Start Docker Desktop (Applications → Docker)

### Docker Desktop memory limit

**Solution:** Docker menu → Preferences → Resources → Increase Memory

---

## Linux Specific

### "Permission denied" with Docker

**Cause:** Docker requires sudo

**Solution:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

Then logout/login.

### "/var/run/docker.sock" permission denied

**Solution:**
```bash
sudo chmod 666 /var/run/docker.sock
```

---

## Debugging

### View all logs

```bash
docker compose logs -f
```

### View specific service logs

```bash
docker compose logs -f frontend
docker compose logs -f backend
docker compose logs -f neo4j
```

### Execute command in container

```bash
# Bash in container
docker compose exec backend bash

# Python shell
docker compose exec backend python

# Neo4j CLI
docker compose exec neo4j cypher-shell
```

### Check resource usage

```bash
docker stats
```

### Inspect network

```bash
docker compose exec backend ping neo4j
```

---

## Full Reset

Nuclear option — removes everything:

```bash
# Stop all services
docker compose down

# Remove volumes (persistent data)
docker compose down -v

# Remove images
docker rmi musicgraph_frontend musicgraph_backend neo4j

# Clean up
docker system prune -a

# Start fresh
docker compose up --build
```

---

## Getting Help

1. **Check logs:** `docker compose logs`
2. **Read docs:** [README.md](README.md), [INSTALLATION.md](INSTALLATION.md)
3. **API reference:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
4. **Source code:** Check comments in code

---

## Still Stuck?

Try these steps in order:

1. Stop all services: `docker compose down`
2. Remove volumes: `docker compose down -v`
3. Clean cache: `docker system prune`
4. Restart: `docker compose up --build`
5. Check logs: `docker compose logs`

If issue persists, check the specific error in this guide.

---

**Most issues are resolved by:**
```bash
docker compose down -v
docker compose up --build
```

Try it first! 🎵
