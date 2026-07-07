import os
from neo4j import GraphDatabase
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "neo4j")

_driver: Optional[GraphDatabase.driver] = None


def get_driver():
    global _driver
    if _driver is None:
        _driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
    return _driver


def close_driver():
    global _driver
    if _driver is not None:
        _driver.close()
        _driver = None


def create_or_update_artist(mbid: str, name: str, country: Optional[str] = None, type_: Optional[str] = None, begin_date: Optional[str] = None, disambiguation: Optional[str] = None):
    drv = get_driver()
    query = (
        "MERGE (a:Artist {mbid: $mbid})\n"
        "SET a.name = $name, a.country = $country, a.type = $type, a.beginDate = $beginDate, a.disambiguation = $disambiguation, a.updated_at = datetime()\n"
        "RETURN a"
    )
    with drv.session() as session:
        result = session.run(query, mbid=mbid, name=name, country=country, type=type_, beginDate=begin_date, disambiguation=disambiguation)
        return result.single()


def mark_artist_imported(mbid: str):
    """Flag an artist as explicitly imported by the user (vs auto-created as a
    collaborator during enrichment). Used to filter the "Library" page."""
    drv = get_driver()
    query = "MATCH (a:Artist {mbid: $mbid}) SET a.imported = true RETURN a"
    with drv.session() as session:
        return session.run(query, mbid=mbid).single()


def create_or_update_recording(mbid: str, name: str, length_ms: Optional[int] = None) -> Dict[str, Any]:
    """Create or update a Recording node."""
    drv = get_driver()
    query = (
        "MERGE (r:Recording {mbid: $mbid})\n"
        "SET r.name = $name, r.length_ms = $length_ms, r.updated_at = datetime()\n"
        "RETURN r"
    )
    with drv.session() as session:
        result = session.run(query, mbid=mbid, name=name, length_ms=length_ms)
        record = result.single()
        return dict(record["r"]) if record else None


def create_or_update_release(mbid: str, name: str, release_date: Optional[str] = None, type_: Optional[str] = None) -> Dict[str, Any]:
    """Create or update a Release node."""
    drv = get_driver()
    query = (
        "MERGE (rel:Release {mbid: $mbid})\n"
        "SET rel.name = $name, rel.release_date = $release_date, rel.type = $type, rel.updated_at = datetime()\n"
        "RETURN rel"
    )
    with drv.session() as session:
        result = session.run(query, mbid=mbid, name=name, release_date=release_date, type=type_)
        record = result.single()
        return dict(record["rel"]) if record else None


def update_artist_spotify(
    mbid: str,
    image_url: Optional[str] = None,
    spotify_id: Optional[str] = None,
    spotify_url: Optional[str] = None,
    popularity: Optional[int] = None,
    genres: Optional[List[str]] = None,
    followers: Optional[int] = None,
):
    """Attach Spotify metadata (photo, popularity, genres, ...) to an Artist node."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $mbid})\n"
        "SET a.image_url = $image_url,\n"
        "    a.spotify_id = $spotify_id,\n"
        "    a.spotify_url = $spotify_url,\n"
        "    a.popularity = $popularity,\n"
        "    a.genres = $genres,\n"
        "    a.followers = $followers,\n"
        "    a.imported = true,\n"
        "    a.updated_at = datetime()\n"
        "RETURN a"
    )
    with drv.session() as session:
        result = session.run(
            query,
            mbid=mbid,
            image_url=image_url,
            spotify_id=spotify_id,
            spotify_url=spotify_url,
            popularity=popularity,
            genres=genres,
            followers=followers,
        )
        record = result.single()
        return dict(record["a"]) if record else None


def create_or_update_album(
    spotify_id: str,
    name: str,
    cover_url: Optional[str] = None,
    release_date: Optional[str] = None,
    total_tracks: Optional[int] = None,
    album_type: Optional[str] = None,
    spotify_url: Optional[str] = None,
) -> Dict[str, Any]:
    """Create or update an Album node (sourced from Spotify, keyed by spotify_id)."""
    drv = get_driver()
    query = (
        "MERGE (al:Album {spotify_id: $spotify_id})\n"
        "SET al.name = $name,\n"
        "    al.cover_url = $cover_url,\n"
        "    al.release_date = $release_date,\n"
        "    al.total_tracks = $total_tracks,\n"
        "    al.album_type = $album_type,\n"
        "    al.spotify_url = $spotify_url,\n"
        "    al.updated_at = datetime()\n"
        "RETURN al"
    )
    with drv.session() as session:
        result = session.run(
            query,
            spotify_id=spotify_id,
            name=name,
            cover_url=cover_url,
            release_date=release_date,
            total_tracks=total_tracks,
            album_type=album_type,
            spotify_url=spotify_url,
        )
        record = result.single()
        return dict(record["al"]) if record else None


def create_recording_appears_on_album(recording_mbid: str, album_spotify_id: str, track_number: Optional[int] = None):
    """Create an APPEARS_ON relationship between a Recording and a Spotify Album."""
    drv = get_driver()
    query = (
        "MATCH (r:Recording {mbid: $recording_mbid})\n"
        "MATCH (al:Album {spotify_id: $album_spotify_id})\n"
        "MERGE (r)-[appon:APPEARS_ON]->(al)\n"
        "SET appon.track_number = $track_number\n"
        "RETURN appon"
    )
    with drv.session() as session:
        result = session.run(query, recording_mbid=recording_mbid, album_spotify_id=album_spotify_id, track_number=track_number)
        return result.single()


def create_released_relationship(artist_mbid: str, album_spotify_id: str):
    """Create a RELEASED relationship between an Artist and a Spotify Album."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})\n"
        "MATCH (al:Album {spotify_id: $album_spotify_id})\n"
        "MERGE (a)-[rel:RELEASED]->(al)\n"
        "RETURN rel"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, album_spotify_id=album_spotify_id)
        return result.single()


def get_artist_albums(artist_mbid: str, limit: int = 50) -> List[Dict[str, Any]]:
    """Fetch all albums released by an artist, most recent first."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})-[:RELEASED]->(al:Album)\n"
        "RETURN al\n"
        "ORDER BY al.release_date DESC\n"
        "LIMIT $limit"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, limit=limit)
        return [dict(record["al"]) for record in result]


def create_performed_relationship(artist_mbid: str, recording_mbid: str, position: Optional[int] = None):
    """Create a PERFORMED relationship between Artist and Recording."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})\n"
        "MATCH (r:Recording {mbid: $recording_mbid})\n"
        "MERGE (a)-[rel:PERFORMED]->(r)\n"
        "SET rel.position = $position\n"
        "RETURN rel"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, recording_mbid=recording_mbid, position=position)
        return result.single()


def create_featured_on_relationship(artist_mbid: str, recording_mbid: str, credited_as: Optional[str] = None):
    """Create a FEATURED_ON relationship between Artist and Recording."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})\n"
        "MATCH (r:Recording {mbid: $recording_mbid})\n"
        "MERGE (a)-[rel:FEATURED_ON]->(r)\n"
        "SET rel.credited_as = $credited_as\n"
        "RETURN rel"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, recording_mbid=recording_mbid, credited_as=credited_as)
        return result.single()


def create_appears_on_relationship(recording_mbid: str, release_mbid: str, track_number: Optional[int] = None):
    """Create an APPEARS_ON relationship between Recording and Release."""
    drv = get_driver()
    query = (
        "MATCH (r:Recording {mbid: $recording_mbid})\n"
        "MATCH (rel:Release {mbid: $release_mbid})\n"
        "MERGE (r)-[appon:APPEARS_ON]->(rel)\n"
        "SET appon.track_number = $track_number\n"
        "RETURN appon"
    )
    with drv.session() as session:
        result = session.run(query, recording_mbid=recording_mbid, release_mbid=release_mbid, track_number=track_number)
        return result.single()


def create_collaborated_relationship(artist1_mbid: str, artist2_mbid: str):
    """Create a COLLABORATED_WITH relationship between two Artists (bidirectional)."""
    drv = get_driver()
    # Use string comparison to avoid duplicate relationships
    query = (
        "MATCH (a1:Artist {mbid: $mbid1})\n"
        "MATCH (a2:Artist {mbid: $mbid2})\n"
        "WHERE a1.mbid < a2.mbid\n"
        "MERGE (a1)-[collab:COLLABORATED_WITH]-(a2)\n"
        "ON CREATE SET collab.count = 1, collab.updated_at = datetime()\n"
        "ON MATCH SET collab.count = collab.count + 1, collab.updated_at = datetime()\n"
        "RETURN collab"
    )
    with drv.session() as session:
        result = session.run(query, mbid1=artist1_mbid, mbid2=artist2_mbid)
        return result.single()


def get_artist_by_mbid(mbid: str) -> Dict[str, Any]:
    """Fetch an Artist node by MBID."""
    drv = get_driver()
    query = "MATCH (a:Artist {mbid: $mbid}) RETURN a"
    with drv.session() as session:
        result = session.run(query, mbid=mbid)
        record = result.single()
        return dict(record["a"]) if record else None


def get_artist_recordings(artist_mbid: str, limit: int = 50) -> List[Dict[str, Any]]:
    """Fetch all recordings performed by an artist."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})-[rel:PERFORMED|FEATURED_ON]->(r:Recording)\n"
        "RETURN r, rel.position as position, type(rel) as rel_type\n"
        "LIMIT $limit"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, limit=limit)
        return [{"recording": dict(record["r"]), "position": record["position"], "rel_type": record["rel_type"]} for record in result]


def get_artist_recordings_paged(artist_mbid: str, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    """Fetch recordings performed/featured by an artist, paginated, with the
    cover of one album the track appears on (when available)."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})-[rel:PERFORMED|FEATURED_ON]->(r:Recording)\n"
        "OPTIONAL MATCH (r)-[:APPEARS_ON]->(al:Album)\n"
        "WITH r, head(collect(DISTINCT type(rel))) AS rel_type,\n"
        "     head(collect(rel.position)) AS position,\n"
        "     [x IN collect(DISTINCT al) WHERE x IS NOT NULL] AS albums\n"
        "RETURN r, rel_type, position,\n"
        "       [x IN albums WHERE x.cover_url IS NOT NULL | x.cover_url][0] AS cover_url,\n"
        "       [x IN albums | x.name][0] AS album_name\n"
        "ORDER BY coalesce(r.name, '')\n"
        "SKIP $offset LIMIT $limit"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, limit=limit, offset=offset)
        return [
            {
                "recording": dict(record["r"]),
                "rel_type": record["rel_type"],
                "position": record["position"],
                "cover_url": record["cover_url"],
                "album_name": record["album_name"],
            }
            for record in result
        ]


def get_album_recordings(album_spotify_id: str, limit: int = 200) -> List[Dict[str, Any]]:
    """Fetch the tracks (recordings) of an album, ordered by track number,
    each carrying the album cover."""
    drv = get_driver()
    query = (
        "MATCH (r:Recording)-[appon:APPEARS_ON]->(al:Album {spotify_id: $sid})\n"
        "RETURN r, appon.track_number AS track_number,\n"
        "       al.cover_url AS cover_url, al.name AS album_name\n"
        "ORDER BY appon.track_number\n"
        "LIMIT $limit"
    )
    with drv.session() as session:
        result = session.run(query, sid=album_spotify_id, limit=limit)
        return [
            {
                "recording": dict(record["r"]),
                "track_number": record["track_number"],
                "cover_url": record["cover_url"],
                "album_name": record["album_name"],
            }
            for record in result
        ]


def get_artist_collaborations(artist_mbid: str, limit: int = 50) -> List[Dict[str, Any]]:
    """Fetch all collaborators of an artist."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})-[collab:COLLABORATED_WITH]-(collaborator:Artist)\n"
        "RETURN collaborator, collab.count as collaboration_count\n"
        "ORDER BY collab.count DESC\n"
        "LIMIT $limit"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid, limit=limit)
        return [{"artist": dict(record["collaborator"]), "collaboration_count": record["collaboration_count"]} for record in result]


def get_graph_for_artist(artist_mbid: str, depth: int = 2) -> Dict[str, Any]:
    """Fetch the graph around an artist (nodes and relationships) for Cytoscape visualization."""
    drv = get_driver()
    query = (
        "MATCH (a:Artist {mbid: $artist_mbid})\n"
        "OPTIONAL MATCH (a)-[rel:PERFORMED|FEATURED_ON]->(r:Recording)\n"
        "OPTIONAL MATCH (a)-[collab:COLLABORATED_WITH]-(collab_artist:Artist)\n"
        "RETURN a, collect(DISTINCT {recording: r, rel_type: type(rel)}) as recordings,\n"
        "       collect(DISTINCT {artist: collab_artist, collab_type: type(collab)}) as collaborators"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid)
        record = result.single()

        if not record:
            return {"nodes": [], "edges": []}

        nodes = []
        edges = []

        # Add main artist node
        artist_data = dict(record["a"])
        nodes.append({
            "id": artist_data.get("mbid", "unknown"),
            "name": artist_data.get("name", "Unknown"),
            "type": "Artist"
        })

        # Add recording nodes and edges
        recordings = record["recordings"] or []
        for rec_obj in recordings:
            if rec_obj.get("recording"):
                rec_data = dict(rec_obj["recording"])
                rec_id = rec_data.get("mbid", "unknown")
                rel_type = rec_obj.get("rel_type", "PERFORMED")

                # Add recording node
                nodes.append({
                    "id": rec_id,
                    "name": rec_data.get("name", "Unknown"),
                    "type": "Recording"
                })

                # Add edge from artist to recording
                edges.append({
                    "from": artist_data.get("mbid", "unknown"),
                    "to": rec_id,
                    "type": rel_type
                })

        # Add collaborator nodes and edges
        collaborators = record["collaborators"] or []
        for collab_obj in collaborators:
            if collab_obj.get("artist"):
                collab_data = dict(collab_obj["artist"])
                collab_id = collab_data.get("mbid", "unknown")

                # Add collaborator node
                nodes.append({
                    "id": collab_id,
                    "name": collab_data.get("name", "Unknown"),
                    "type": "Artist"
                })

                # Add edge (bidirectional collaboration)
                edges.append({
                    "from": artist_data.get("mbid", "unknown"),
                    "to": collab_id,
                    "type": "COLLABORATED_WITH"
                })

        return {"nodes": nodes, "edges": edges}


def get_stats() -> Dict[str, Any]:
    """Aggregate stats for the dashboard: counts + most-connected artists."""
    drv = get_driver()
    with drv.session() as session:
        imported = session.run(
            "MATCH (a:Artist) WHERE a.imported = true RETURN count(a) AS n"
        ).single()["n"]
        total_artists = session.run("MATCH (a:Artist) RETURN count(a) AS n").single()["n"]
        recordings = session.run("MATCH (r:Recording) RETURN count(r) AS n").single()["n"]
        albums = session.run("MATCH (al:Album) RETURN count(al) AS n").single()["n"]
        collaborations = session.run(
            "MATCH ()-[c:COLLABORATED_WITH]->() RETURN count(c) AS n"
        ).single()["n"]

        top = session.run(
            "MATCH (a:Artist)-[c:COLLABORATED_WITH]-(b:Artist)\n"
            "RETURN a.name AS name, a.mbid AS mbid, a.image_url AS image_url,\n"
            "       count(DISTINCT b) AS collaborators\n"
            "ORDER BY collaborators DESC\n"
            "LIMIT 10"
        )
        top_collaborators = [
            {
                "name": r["name"],
                "mbid": r["mbid"],
                "image_url": r["image_url"],
                "collaborators": r["collaborators"],
            }
            for r in top
        ]

    return {
        "imported_artists": imported,
        "total_artists": total_artists,
        "recordings": recordings,
        "albums": albums,
        "collaborations": collaborations,
        "top_collaborators": top_collaborators,
    }


def detect_collaborations_for_artist(artist_mbid: str):
    """Detect and create COLLABORATED_WITH relationships for an artist based on shared recordings."""
    drv = get_driver()
    query = (
        "MATCH (a1:Artist {mbid: $artist_mbid})-[:PERFORMED|FEATURED_ON]->(r:Recording)\n"
        "<-[:PERFORMED|FEATURED_ON]-(a2:Artist)\n"
        "WHERE a1.mbid < a2.mbid\n"
        "MERGE (a1)-[collab:COLLABORATED_WITH]-(a2)\n"
        "ON CREATE SET collab.count = 1, collab.updated_at = datetime()\n"
        "ON MATCH SET collab.count = collab.count + 1, collab.updated_at = datetime()\n"
        "RETURN collab"
    )
    with drv.session() as session:
        result = session.run(query, artist_mbid=artist_mbid)
        return result.consume().counters
