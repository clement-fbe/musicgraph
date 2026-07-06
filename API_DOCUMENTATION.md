# API Documentation — MusicGraph

Complete reference for all REST API endpoints.

**Base URL:** `http://localhost:8000/api`

**Content-Type:** `application/json`

---

## System

### Health Check

Check if backend is running.

```http
GET /health
```

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

---

## Artists

### Search Artists

Search for artists on MusicBrainz.

```http
GET /search/artists?q=<query>
```

**Parameters:**
- `q` (string, required) — Artist name to search
- `use_mock` (boolean, optional, default: false) — Force mock data

**Example:**
```bash
curl "http://localhost:8000/api/search/artists?q=Daft%20Punk"
```

**Response (200 OK):**
```json
{
  "artists": [
    {
      "id": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
      "name": "Daft Punk",
      "type": "Group",
      "country": "FR",
      "disambiguation": "French electronic music duo"
    }
  ]
}
```

---

### Import Artist

Import an artist from MusicBrainz to Neo4j.

```http
POST /import/artists
Content-Type: application/json

{
  "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56"
}
```

**Request Body:**
- `mbid` (string, required) — MusicBrainz artist ID

**Example:**
```bash
curl -X POST http://localhost:8000/api/import/artists \
  -H "Content-Type: application/json" \
  -d '{"mbid":"056e4f3e-d505-4dad-8ec1-d04f521cbb56"}'
```

**Response (200 OK):**
```json
{
  "status": "imported",
  "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56"
}
```

---

### Enrich Artist

Fetch recordings and detect collaborations for an artist.

```http
POST /enrich/artists
Content-Type: application/json

{
  "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "fetch_recordings": true
}
```

**Request Body:**
- `mbid` (string, required) — Artist MBID
- `fetch_recordings` (boolean, optional, default: true) — Fetch from MusicBrainz

**Response (200 OK):**
```json
{
  "status": "enriched",
  "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "recordings_added": 5
}
```

---

### List All Artists

Get all imported artists.

```http
GET /artists
```

**Response (200 OK):**
```json
{
  "artists": [
    {
      "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
      "name": "Daft Punk",
      "country": "FR",
      "type": "Group",
      "beginDate": "1993-01-01",
      "disambiguation": "French electronic music duo"
    }
  ]
}
```

---

### Get Artist Details

Get artist info with recordings and collaborators.

```http
GET /artists/{mbid}
```

**Parameters:**
- `mbid` (string, required, path) — Artist MBID

**Example:**
```bash
curl http://localhost:8000/api/artists/056e4f3e-d505-4dad-8ec1-d04f521cbb56
```

**Response (200 OK):**
```json
{
  "artist": {
    "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
    "name": "Daft Punk",
    "country": "FR",
    "type": "Group",
    "beginDate": "1993-01-01"
  },
  "recordings": [
    {
      "recording": {
        "mbid": "rec-001",
        "name": "Get Lucky",
        "length_ms": 246000
      },
      "rel_type": "PERFORMED"
    }
  ],
  "collaborators": [
    {
      "artist": {
        "mbid": "collaborator-001",
        "name": "Pharrell Williams",
        "type": "Person"
      },
      "collaboration_count": 1
    }
  ]
}
```

**Error (404 Not Found):**
```json
{
  "detail": "Artist not found"
}
```

---

### Get Collaborators

Get all collaborators of an artist.

```http
GET /artists/{mbid}/collaborations
```

**Parameters:**
- `mbid` (string, required, path) — Artist MBID

**Response (200 OK):**
```json
{
  "artist_mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "collaborators": [
    {
      "artist": {
        "mbid": "collaborator-001",
        "name": "Pharrell Williams",
        "type": "Person",
        "country": "US"
      },
      "collaboration_count": 1
    }
  ]
}
```

**Error (404 Not Found):**
```json
{
  "detail": "Artist not found or has no collaborations"
}
```

---

## Graph

### Get Artist Graph

Get the full graph around an artist (nodes + relationships).

```http
GET /graph/{mbid}?depth=2
```

**Parameters:**
- `mbid` (string, required, path) — Artist MBID
- `depth` (integer, optional, default: 2) — Traversal depth

**Example:**
```bash
curl "http://localhost:8000/api/graph/056e4f3e-d505-4dad-8ec1-d04f521cbb56?depth=2"
```

**Response (200 OK):**
```json
{
  "graph": {
    "artist": {
      "mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
      "name": "Daft Punk"
    },
    "recordings": [
      {
        "recording": {
          "mbid": "rec-001",
          "name": "Get Lucky"
        },
        "rel_type": "PERFORMED"
      }
    ],
    "releases": [
      {
        "mbid": "rel-001",
        "name": "Random Access Memories"
      }
    ],
    "collaborators": [
      {
        "artist": {
          "mbid": "collab-001",
          "name": "Pharrell Williams"
        },
        "count": 1
      }
    ]
  }
}
```

---

## Recordings

### Create Recording

Manually create a recording and link to artist.

```http
POST /recordings
Content-Type: application/json

{
  "recording_mbid": "rec-001",
  "recording_name": "Get Lucky",
  "artist_mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "length_ms": 246000
}
```

**Request Body:**
- `recording_mbid` (string, required) — Unique recording ID
- `recording_name` (string, required) — Recording title
- `artist_mbid` (string, required) — Artist MBID
- `length_ms` (integer, optional) — Duration in milliseconds

**Response (200 OK):**
```json
{
  "status": "created",
  "recording_mbid": "rec-001"
}
```

---

## Collaborations

### Detect Collaboration

Manually create a collaboration relationship between two artists.

```http
POST /collaborations/detect
Content-Type: application/json

{
  "artist1_mbid": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "artist2_mbid": "pharrell-001"
}
```

**Request Body:**
- `artist1_mbid` (string, required) — First artist MBID
- `artist2_mbid` (string, required) — Second artist MBID

**Response (200 OK):**
```json
{
  "status": "created",
  "artist1": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
  "artist2": "pharrell-001"
}
```

---

## Error Handling

All errors return JSON with detail message.

### 400 Bad Request
```json
{
  "detail": "Invalid request parameters"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## Rate Limiting

- **MusicBrainz API:** Rate limited by external service
- **Backend:** No rate limiting (local development)
- **Retry Logic:** Automatic retry (3 attempts) with exponential backoff

---

## Data Types

### Artist Object
```json
{
  "mbid": "string (UUID)",
  "name": "string",
  "country": "string (ISO code)",
  "type": "string (Person, Group, Orchestra, etc.)",
  "beginDate": "string (YYYY or YYYY-MM-DD)",
  "endDate": "string (YYYY or YYYY-MM-DD, optional)",
  "disambiguation": "string (optional)"
}
```

### Recording Object
```json
{
  "mbid": "string (UUID)",
  "name": "string",
  "length_ms": "integer (optional)"
}
```

### Release Object
```json
{
  "mbid": "string (UUID)",
  "name": "string",
  "release_date": "string (YYYY-MM-DD, optional)",
  "type": "string (Album, Single, EP, etc., optional)"
}
```

---

## Examples

### Complete Workflow

```bash
# 1. Search
curl "http://localhost:8000/api/search/artists?q=Daft%20Punk"

# 2. Import (use MBID from search result)
curl -X POST http://localhost:8000/api/import/artists \
  -H "Content-Type: application/json" \
  -d '{"mbid":"056e4f3e-d505-4dad-8ec1-d04f521cbb56"}'

# 3. Get details
curl http://localhost:8000/api/artists/056e4f3e-d505-4dad-8ec1-d04f521cbb56

# 4. Get collaborations
curl http://localhost:8000/api/artists/056e4f3e-d505-4dad-8ec1-d04f521cbb56/collaborations

# 5. Get graph
curl http://localhost:8000/api/graph/056e4f3e-d505-4dad-8ec1-d04f521cbb56
```

---

## Response Times

Typical response times:
- Search: 200-500ms
- Import: 100-300ms
- Get artist: 50-150ms
- Get graph: 100-500ms

---

## Support

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

For full documentation, see [README.md](README.md).
