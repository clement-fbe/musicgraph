import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { artistAPI } from '../api'
import './ArtistDetail.css'

export default function ArtistDetail() {
  const { mbid } = useParams()
  const navigate = useNavigate()
  const [artist, setArtist] = useState(null)
  const [recordings, setRecordings] = useState([])
  const [collaborators, setCollaborators] = useState([])
  const [albums, setAlbums] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await artistAPI.getById(mbid)
        setArtist(response.data.artist)
        setRecordings(response.data.recordings || [])
        setCollaborators(response.data.collaborators || [])
        setAlbums(response.data.albums || [])
      } catch (err) {
        setError('Artist not found or error loading data')
        console.error(err)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [mbid])

  if (loading) return <div className="page-content"><div className="loading">Loading...</div></div>
  if (error) return <div className="page-content"><div className="error">{error}</div></div>
  if (!artist) return <div className="page-content"><div className="error">Artist not found</div></div>

  return (
    <div className="page-content">
      <div className="container">
        <div className="action-buttons">
          <button className="back-btn" onClick={() => navigate(-1)}>← Back</button>
          <button className="graph-btn" onClick={() => navigate(`/graph/${mbid}`)}>📊 View Graph</button>
        </div>

        <div className="artist-detail card">
          {artist.image_url && (
            <img className="artist-photo" src={artist.image_url} alt={artist.name} />
          )}
          <div className="artist-detail-body">
            <div className="artist-header-detail">
              <h1>{artist.name}</h1>
              <span className="badge primary">{artist.type || 'Artist'}</span>
            </div>

            <div className="artist-meta-detail">
              {artist.country && <p><strong>Country:</strong> {artist.country}</p>}
              {artist.beginDate && <p><strong>Since:</strong> {artist.beginDate}</p>}
              {artist.disambiguation && <p><strong>Description:</strong> {artist.disambiguation}</p>}
              {typeof artist.popularity === 'number' && (
                <p><strong>Popularity:</strong> {artist.popularity}/100</p>
              )}
              {artist.followers != null && (
                <p><strong>Followers:</strong> {artist.followers.toLocaleString()}</p>
              )}
              {Array.isArray(artist.genres) && artist.genres.length > 0 && (
                <p className="genres">
                  {artist.genres.map((g) => (
                    <span key={g} className="badge genre">{g}</span>
                  ))}
                </p>
              )}
              <p className="mbid"><strong>MBID:</strong> {artist.mbid}</p>
              {artist.spotify_url && (
                <p><a href={artist.spotify_url} target="_blank" rel="noreferrer">Open on Spotify ↗</a></p>
              )}
            </div>
          </div>
        </div>

        {albums.length > 0 && (
          <section className="section card">
            <h2>💿 Albums ({albums.length})</h2>
            <div className="albums-grid">
              {albums.map((album) => (
                <a
                  key={album.spotify_id}
                  className="album-cover-item"
                  href={album.spotify_url || '#'}
                  target={album.spotify_url ? '_blank' : undefined}
                  rel="noreferrer"
                >
                  {album.cover_url ? (
                    <img src={album.cover_url} alt={album.name} loading="lazy" />
                  ) : (
                    <div className="album-cover-placeholder">🎵</div>
                  )}
                  <div className="album-cover-title">{album.name}</div>
                  {album.release_date && (
                    <div className="album-cover-date">{album.release_date.slice(0, 4)}</div>
                  )}
                </a>
              ))}
            </div>
          </section>
        )}

        <div className="sections">
          <section className="section card">
            <h2>🎼 Recordings ({recordings.length})</h2>
            {recordings.length > 0 ? (
              <div className="recordings-list">
                {recordings.map((rec, idx) => (
                  <div key={idx} className="recording-item">
                    <div>
                      <h4>{rec.recording?.name || 'Unknown'}</h4>
                      <p className="recording-type">
                        <span className="badge">{rec.rel_type || 'PERFORMED'}</span>
                      </p>
                    </div>
                    {rec.recording?.length_ms && (
                      <p className="duration">
                        {Math.round(rec.recording.length_ms / 1000)}s
                      </p>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="empty">No recordings found</p>
            )}
          </section>

          <section className="section card">
            <h2>🤝 Collaborators ({collaborators.length})</h2>
            {collaborators.length > 0 ? (
              <div className="collaborators-list">
                {collaborators.map((collab, idx) => (
                  <div
                    key={idx}
                    className="collaborator-item"
                    onClick={() => navigate(`/artist/${collab.artist.mbid}`)}
                    style={{ cursor: 'pointer' }}
                  >
                    <div>
                      <h4>{collab.artist.name}</h4>
                      <p className="collab-type">{collab.artist.type || 'Artist'}</p>
                    </div>
                    <span className="collab-count">
                      {collab.collaboration_count || 1} collab{(collab.collaboration_count || 1) !== 1 ? 's' : ''}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="empty">No collaborators found</p>
            )}
          </section>
        </div>
      </div>
    </div>
  )
}
