from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os
import httpx
from dotenv import load_dotenv
from app.neo4j_client import (
    create_or_update_artist,
    mark_artist_imported,
    create_or_update_recording,
    create_or_update_release,
    create_performed_relationship,
    create_appears_on_relationship,
    detect_collaborations_for_artist,
    get_artist_by_mbid,
    get_artist_recordings,
    get_artist_collaborations,
    get_graph_for_artist
)
from app.neo4j_client import (
    update_artist_spotify,
    create_or_update_album,
    create_released_relationship,
    create_featured_on_relationship,
    create_recording_appears_on_album,
    get_artist_albums,
    get_stats,
)
from app.musicbrainz_mock import get_mock_search, get_mock_artist
from app import spotify_client
import time
import logging

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="MusicGraph Backend")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:3001",
        "http://0.0.0.0:3000",
        "http://0.0.0.0:3001",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MUSICBRAINZ_BASE = os.getenv("MUSICBRAINZ_BASE", "https://musicbrainz.org/ws/2")
USER_AGENT = os.getenv("MUSICBRAINZ_USER_AGENT", "MusicGraph/1.0 (mehdilmbn@gmail.com)")

class ImportRequest(BaseModel):
    mbid: str
    # Optional artist data sent by the frontend (from search results).
    # When present, we use it directly instead of re-fetching from MusicBrainz,
    # which makes import reliable even when the MusicBrainz API is rate-limited.
    name: Optional[str] = None
    country: Optional[str] = None
    type: Optional[str] = None
    disambiguation: Optional[str] = None
    begin_date: Optional[str] = None


class EnrichArtistRequest(BaseModel):
    mbid: str
    fetch_recordings: bool = True


class EnrichSpotifyRequest(BaseModel):
    mbid: str
    # Optional name hint; if omitted we read the artist's name from Neo4j.
    name: Optional[str] = None


class CreateRecordingRequest(BaseModel):
    recording_mbid: str
    recording_name: str
    artist_mbid: str
    length_ms: Optional[int] = None


class CreateCollaborationRequest(BaseModel):
    artist1_mbid: str
    artist2_mbid: str


@app.get("/api/health")
async def health():
    logger.info("✅ Health check called")
    return {"status": "ok"}


@app.get("/api/cors-test")
async def cors_test():
    logger.info("🔍 CORS test endpoint called")
    return {"cors": "working", "message": "If you see this, CORS is configured correctly"}


@app.get("/api/search/artists")
async def search_artists(q: str, use_mock: bool = False):
    """Search artists via Spotify (the app's primary data source)."""
    logger.info(f"🔍 Search request received: q='{q}'")

    if not q:
        logger.error("❌ Query parameter 'q' is required")
        raise HTTPException(status_code=400, detail="Query parameter 'q' required")

    if not spotify_client.is_configured():
        logger.error("❌ Spotify is not configured")
        return {"artists": [], "source": "spotify", "spotify_available": False}

    import asyncio
    artists = await asyncio.to_thread(spotify_client.search_artists, q)
    logger.info(f"📊 Spotify search for '{q}' returned {len(artists)} artists")
    return {"artists": artists, "source": "spotify", "spotify_available": True}


@app.post("/api/import/artists")
async def import_artist(req: ImportRequest):
    """Insert an artist into Neo4j.

    Strategy (most reliable first):
    1. If the frontend sent artist data (from search results), use it directly.
    2. Otherwise try the MusicBrainz API with retries.
    3. Fall back to bundled mock data.
    """
    import asyncio

    logger.info(f"📥 Import request for mbid='{req.mbid}', name='{req.name}'")

    artist = None

    # 1. Use data provided by the frontend (always available from search results)
    if req.name:
        logger.info(f"✅ Using artist data sent by frontend for '{req.name}'")
        artist = {
            "name": req.name,
            "country": req.country,
            "type": req.type,
            "disambiguation": req.disambiguation,
            "life-span": {"begin": req.begin_date} if req.begin_date else {},
        }
    else:
        # 2. Try MusicBrainz API with retries
        headers = {"User-Agent": USER_AGENT}
        max_retries = 3
        for attempt in range(max_retries):
            try:
                def sync_request():
                    with httpx.Client(timeout=10.0, follow_redirects=True) as client:
                        resp = client.get(f"{MUSICBRAINZ_BASE}/artist/{req.mbid}", params={"fmt": "json"}, headers=headers)
                        resp.raise_for_status()
                        return resp.json()
                artist = await asyncio.to_thread(sync_request)
                logger.info(f"✅ MusicBrainz import succeeded for '{req.mbid}' on attempt {attempt + 1}")
                break
            except Exception as e:
                logger.warning(f"⚠️ MusicBrainz API attempt {attempt + 1}/{max_retries} failed: {type(e).__name__}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(0.5 * (attempt + 1))  # Exponential backoff

        # 3. Fall back to mock data
        if not artist:
            logger.info(f"🔄 Falling back to mock data for import of '{req.mbid}'")
            artist = get_mock_artist(req.mbid)

    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found (no data provided, MusicBrainz unavailable, and not in mock data)")

    # Extract minimal fields from artist
    name = artist.get("name")
    country = artist.get("country")
    type_ = artist.get("type")
    begin_date = None
    life_span = artist.get("life-span") or {}
    if life_span:
        begin_date = life_span.get("begin")
    disambiguation = artist.get("disambiguation")

    create_or_update_artist(req.mbid, name, country=country, type_=type_, begin_date=begin_date, disambiguation=disambiguation)
    mark_artist_imported(req.mbid)
    logger.info(f"✅ Artist '{name}' ({req.mbid}) imported into Neo4j")
    return {"status": "imported", "mbid": req.mbid}


def _enrich_with_spotify(mbid: str, name: Optional[str] = None) -> dict:
    """Enrich an artist entirely from Spotify and store the graph in Neo4j.

    `mbid` holds the Spotify artist id (that's what search stores). Fetches the
    artist photo, albums (with covers), their tracks (as Recording nodes) and
    detects collaborations/featurings from tracks crediting more than one
    artist. Best-effort: returns a status dict and never raises.
    """
    if not spotify_client.is_configured():
        return {"status": "spotify_not_configured", "mbid": mbid}

    # Fetch the artist directly by id; fall back to a name search if needed.
    info = spotify_client.get_artist(mbid)
    spotify_id = info.get("spotify_id") if info else None
    if not spotify_id:
        if not name:
            artist = get_artist_by_mbid(mbid)
            name = artist.get("name") if artist else None
        info = spotify_client.search_artist(name) if name else None
        spotify_id = info.get("spotify_id") if info else None
    if not spotify_id:
        logger.warning(f"No Spotify artist for '{mbid}'")
        return {"status": "no_spotify_match", "mbid": mbid}

    # Artist photo / metadata on the main node.
    update_artist_spotify(
        mbid,
        image_url=info.get("image_url"),
        spotify_id=spotify_id,
        spotify_url=info.get("spotify_url"),
        popularity=info.get("popularity"),
        genres=info.get("genres"),
        followers=info.get("followers"),
    )

    albums = spotify_client.get_artist_albums(spotify_id)

    albums_added = 0
    recordings_added = 0
    collaborators_added = 0
    seen_tracks = set()  # dedupe recordings by lowercased title
    MAX_ALBUMS = 15
    MAX_RECORDINGS = 120

    for album in albums[:MAX_ALBUMS]:
        alb_id = album.get("spotify_id")
        if not alb_id or not album.get("name"):
            continue
        try:
            create_or_update_album(
                alb_id, album["name"],
                cover_url=album.get("cover_url"),
                release_date=album.get("release_date"),
                total_tracks=album.get("total_tracks"),
                album_type=album.get("album_type"),
                spotify_url=album.get("spotify_url"),
            )
            create_released_relationship(mbid, alb_id)
            albums_added += 1
        except Exception as e:
            logger.warning(f"Error storing album {album.get('name')}: {type(e).__name__}")
            continue

        if recordings_added >= MAX_RECORDINGS:
            continue

        for track in spotify_client.get_album_tracks(alb_id):
            if recordings_added >= MAX_RECORDINGS:
                break
            t_id = track.get("spotify_id")
            t_name = track.get("name")
            if not t_id or not t_name:
                continue
            key = t_name.strip().lower()
            if key in seen_tracks:
                # Already have this song; just link it to this album too.
                try:
                    create_recording_appears_on_album(t_id, alb_id, track_number=track.get("track_number"))
                except Exception:
                    pass
                continue
            seen_tracks.add(key)
            try:
                create_or_update_recording(t_id, t_name, length_ms=track.get("duration_ms"))
                create_recording_appears_on_album(t_id, alb_id, track_number=track.get("track_number"))

                # Credit the track artists: the main artist PERFORMED, the
                # others are FEATURED_ON (i.e. collaborators).
                for ar in track.get("artists", []):
                    ar_id = ar.get("id")
                    if not ar_id:
                        continue
                    if ar_id == spotify_id:
                        create_performed_relationship(mbid, t_id)
                    else:
                        create_or_update_artist(ar_id, ar.get("name"), type_="Artist")
                        create_featured_on_relationship(ar_id, t_id, credited_as=ar.get("name"))
                        collaborators_added += 1
                recordings_added += 1
            except Exception as e:
                logger.warning(f"Error processing track {t_name}: {type(e).__name__}")
                continue

    # Turn shared recordings into COLLABORATED_WITH edges.
    try:
        detect_collaborations_for_artist(mbid)
    except Exception as e:
        logger.warning(f"Error detecting collaborations: {type(e).__name__}")

    logger.info(f"✅ Spotify enrichment '{mbid}': albums={albums_added}, recordings={recordings_added}, collaborators={collaborators_added}")
    return {
        "status": "enriched",
        "mbid": mbid,
        "image_url": info.get("image_url"),
        "albums_added": albums_added,
        "recordings_added": recordings_added,
        "collaborators_added": collaborators_added,
    }


@app.get("/api/spotify/status")
async def spotify_status():
    """Report whether Spotify credentials are configured (for the frontend)."""
    return {"configured": spotify_client.is_configured()}


@app.post("/api/enrich/spotify")
async def enrich_spotify(req: EnrichSpotifyRequest):
    """Enrich an artist with Spotify data (photo, popularity, genres, album covers)."""
    import asyncio
    return await asyncio.to_thread(_enrich_with_spotify, req.mbid, req.name)


@app.post("/api/enrich/artists")
async def enrich_artist(req: EnrichArtistRequest):
    """Enrich an artist from Spotify: photo, albums, tracks and collaborations."""
    if not req.fetch_recordings:
        return {"status": "skipped", "mbid": req.mbid}
    import asyncio
    return await asyncio.to_thread(_enrich_with_spotify, req.mbid)


@app.get("/api/artists")
async def get_all_artists():
    """Get all artists in the database."""
    from app.neo4j_client import get_driver
    drv = get_driver()
    # Only artists explicitly imported by the user — not collaborator nodes
    # auto-created during enrichment (those still populate the graph).
    query = "MATCH (a:Artist) WHERE a.imported = true RETURN a LIMIT 100"
    with drv.session() as session:
        result = session.run(query)
        artists = [dict(record["a"]) for record in result]
    return {"artists": artists}


@app.get("/api/stats")
async def stats():
    """Dashboard statistics computed from the graph."""
    return get_stats()


@app.get("/api/artists/{artist_mbid}")
async def get_artist_details(artist_mbid: str):
    """Get detailed information about an artist."""
    artist = get_artist_by_mbid(artist_mbid)
    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found")

    recordings = get_artist_recordings(artist_mbid)
    collaborators = get_artist_collaborations(artist_mbid)
    albums = get_artist_albums(artist_mbid)

    return {
        "artist": artist,
        "recordings": recordings,
        "collaborators": collaborators,
        "albums": albums
    }


@app.get("/api/artists/{artist_mbid}/collaborations")
async def get_collaborations(artist_mbid: str):
    """Get all collaborators of an artist."""
    collaborators = get_artist_collaborations(artist_mbid)
    if not collaborators:
        raise HTTPException(status_code=404, detail="Artist not found or has no collaborations")

    return {"artist_mbid": artist_mbid, "collaborators": collaborators}


@app.get("/api/graph/{artist_mbid}")
async def get_artist_graph(artist_mbid: str, depth: int = 2):
    """Get the graph around an artist."""
    graph = get_graph_for_artist(artist_mbid, depth=depth)
    if not graph:
        raise HTTPException(status_code=404, detail="Artist not found")

    return {"graph": graph}


@app.post("/api/recordings")
async def create_recording(req: CreateRecordingRequest):
    """Manually create a recording and link it to an artist (for testing)."""
    try:
        # Create recording
        create_or_update_recording(req.recording_mbid, req.recording_name, length_ms=req.length_ms)

        # Create PERFORMED relationship
        create_performed_relationship(req.artist_mbid, req.recording_mbid)

        logger.info(f"Recording created: {req.recording_mbid} - {req.recording_name}")
        return {"status": "created", "recording_mbid": req.recording_mbid}
    except Exception as e:
        logger.error(f"Error creating recording: {type(e).__name__} - {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error creating recording: {str(e)}")


@app.post("/api/collaborations/detect")
async def detect_collaborations(req: CreateCollaborationRequest):
    """Manually create a collaboration between two artists."""
    try:
        from app.neo4j_client import create_collaborated_relationship
        create_collaborated_relationship(req.artist1_mbid, req.artist2_mbid)
        logger.info(f"Collaboration created: {req.artist1_mbid} <-> {req.artist2_mbid}")
        return {"status": "created", "artist1": req.artist1_mbid, "artist2": req.artist2_mbid}
    except Exception as e:
        logger.error(f"Error creating collaboration: {type(e).__name__} - {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error creating collaboration: {str(e)}")
