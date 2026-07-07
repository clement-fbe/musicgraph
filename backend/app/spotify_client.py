"""Spotify Web API client (Client Credentials flow).

Only public catalog data is needed (artist images, album covers, genres,
popularity) so we use the app-level Client Credentials flow — no user login
and no Spotify Premium required. Set SPOTIFY_CLIENT_ID and
SPOTIFY_CLIENT_SECRET in the environment to enable it.

If the credentials are missing the client degrades gracefully: is_configured()
returns False and every fetch returns None/[] so the rest of the app keeps
working without covers.
"""
import base64
import logging
import os
import time
from typing import Any, Dict, List, Optional

import httpx
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

CLIENT_ID = os.getenv("SPOTIFY_CLIENT_ID", "").strip()
CLIENT_SECRET = os.getenv("SPOTIFY_CLIENT_SECRET", "").strip()

TOKEN_URL = "https://accounts.spotify.com/api/token"
API_BASE = "https://api.spotify.com/v1"

# Simple module-level token cache (access token + absolute expiry timestamp).
_token: Optional[str] = None
_token_expiry: float = 0.0


def is_configured() -> bool:
    """True when both Spotify credentials are present."""
    return bool(CLIENT_ID and CLIENT_SECRET)


def _get_token() -> Optional[str]:
    """Return a valid access token, refreshing it if needed. None on failure."""
    global _token, _token_expiry

    if not is_configured():
        return None

    # Reuse the cached token until ~60s before it expires.
    if _token and time.time() < _token_expiry - 60:
        return _token

    auth = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()
    headers = {
        "Authorization": f"Basic {auth}",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    try:
        with httpx.Client(timeout=10.0) as client:
            resp = client.post(TOKEN_URL, data={"grant_type": "client_credentials"}, headers=headers)
            resp.raise_for_status()
            payload = resp.json()
        _token = payload["access_token"]
        _token_expiry = time.time() + int(payload.get("expires_in", 3600))
        logger.info("✅ Spotify access token obtained")
        return _token
    except Exception as e:
        logger.warning(f"⚠️ Could not obtain Spotify token: {type(e).__name__}: {e}")
        return None


def _api_get(path: str, params: Dict[str, Any]) -> Optional[dict]:
    """GET a Spotify API endpoint with the cached token. None on failure."""
    token = _get_token()
    if not token:
        return None
    try:
        with httpx.Client(timeout=15.0) as client:
            resp = client.get(
                f"{API_BASE}{path}",
                params=params,
                headers={"Authorization": f"Bearer {token}"},
            )
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        logger.warning(f"⚠️ Spotify API GET {path} failed: {type(e).__name__}: {e}")
        return None


def _largest_image(images: List[dict]) -> Optional[str]:
    """Return the URL of the largest image in a Spotify images array."""
    if not images:
        return None
    # Spotify returns images ordered largest-first, but sort defensively.
    best = max(images, key=lambda im: (im.get("width") or 0) * (im.get("height") or 0))
    return best.get("url")


def search_artist(name: str) -> Optional[Dict[str, Any]]:
    """Find the best-matching Spotify artist by name.

    Returns a dict with spotify_id, image_url, genres, popularity, followers and
    spotify_url, or None if not configured / not found.
    """
    if not name:
        return None
    data = _api_get("/search", {"q": name, "type": "artist", "limit": 5})
    if not data:
        return None

    items = data.get("artists", {}).get("items", [])
    if not items:
        return None

    # Prefer an exact (case-insensitive) name match, else the most popular result.
    lname = name.strip().lower()
    exact = [a for a in items if (a.get("name") or "").strip().lower() == lname]
    best = exact[0] if exact else max(items, key=lambda a: a.get("popularity", 0))

    return {
        "spotify_id": best.get("id"),
        "name": best.get("name"),
        "image_url": _largest_image(best.get("images", [])),
        "genres": best.get("genres", []),
        "popularity": best.get("popularity"),
        "followers": (best.get("followers") or {}).get("total"),
        "spotify_url": (best.get("external_urls") or {}).get("spotify"),
    }


# Some Spotify apps cap the albums endpoint at limit=10 (values >10 return a
# "400 Invalid limit"). We page through with a safe size and stop once we have
# enough unique albums.
_ALBUMS_PAGE_SIZE = 10


def search_artists(name: str, limit: int = 8) -> List[Dict[str, Any]]:
    """Search Spotify artists by name, returning a list mapped for the frontend.

    Each item exposes both `id` and `mbid` set to the Spotify artist id so the
    existing frontend/routing/Neo4j code (which keys on `mbid`) keeps working.
    """
    if not name:
        return []
    data = _api_get("/search", {"q": name, "type": "artist", "limit": limit})
    if not data:
        return []
    results = []
    for a in data.get("artists", {}).get("items", []):
        sid = a.get("id")
        if not sid:
            continue
        results.append({
            "id": sid,
            "mbid": sid,  # Spotify id stored where the app expects an MBID
            "name": a.get("name"),
            "type": "Artist",
            "image_url": _largest_image(a.get("images", [])),
            "spotify_url": (a.get("external_urls") or {}).get("spotify"),
        })
    return results


def get_artist(spotify_artist_id: str) -> Optional[Dict[str, Any]]:
    """Fetch a single Spotify artist by id (name + image)."""
    if not spotify_artist_id:
        return None
    a = _api_get(f"/artists/{spotify_artist_id}", {})
    if not a:
        return None
    return {
        "spotify_id": a.get("id"),
        "name": a.get("name"),
        "image_url": _largest_image(a.get("images", [])),
        "genres": a.get("genres", []),
        "popularity": a.get("popularity"),
        "followers": (a.get("followers") or {}).get("total"),
        "spotify_url": (a.get("external_urls") or {}).get("spotify"),
    }


def get_album_tracks(album_spotify_id: str) -> List[Dict[str, Any]]:
    """Fetch an album's tracks with their credited artists.

    Each track exposes its artists (id + name) so collaborations/featurings can
    be detected (a track with >1 artist = a collaboration). Paginated at 10
    because this app caps the page size at 10.
    """
    if not album_spotify_id:
        return []
    tracks: List[Dict[str, Any]] = []
    offset = 0
    while True:
        data = _api_get(
            f"/albums/{album_spotify_id}/tracks",
            {"limit": _ALBUMS_PAGE_SIZE, "offset": offset, "market": "US"},
        )
        if not data:
            break
        items = data.get("items", [])
        if not items:
            break
        for t in items:
            tracks.append({
                "spotify_id": t.get("id"),
                "name": t.get("name"),
                "duration_ms": t.get("duration_ms"),
                "track_number": t.get("track_number"),
                "preview_url": t.get("preview_url"),
                "artists": [
                    {"id": ar.get("id"), "name": ar.get("name")}
                    for ar in t.get("artists", []) if ar.get("id")
                ],
            })
        if len(items) < _ALBUMS_PAGE_SIZE:
            break
        offset += _ALBUMS_PAGE_SIZE
    return tracks


def get_artist_albums(spotify_artist_id: str, limit: int = 30) -> List[Dict[str, Any]]:
    """Return the artist's albums + singles with their cover URLs (deduped by name).

    Paginates with offset (page size 10) because some apps reject limit > 10.
    """
    if not spotify_artist_id:
        return []

    albums: List[Dict[str, Any]] = []
    seen_names = set()
    offset = 0

    while len(albums) < limit:
        data = _api_get(
            f"/artists/{spotify_artist_id}/albums",
            {
                "include_groups": "album,single",
                "limit": _ALBUMS_PAGE_SIZE,
                "offset": offset,
                "market": "US",
            },
        )
        if not data:
            break

        items = data.get("items", [])
        if not items:
            break

        for item in items:
            name = item.get("name")
            # Spotify lists many editions of the same album — keep the first only.
            key = (name or "").strip().lower()
            if not name or key in seen_names:
                continue
            seen_names.add(key)
            albums.append({
                "spotify_id": item.get("id"),
                "name": name,
                "cover_url": _largest_image(item.get("images", [])),
                "release_date": item.get("release_date"),
                "total_tracks": item.get("total_tracks"),
                "album_type": item.get("album_type"),
                "spotify_url": (item.get("external_urls") or {}).get("spotify"),
            })

        # Last page reached when the API returns fewer items than requested.
        if len(items) < _ALBUMS_PAGE_SIZE:
            break
        offset += _ALBUMS_PAGE_SIZE

    return albums[:limit]
