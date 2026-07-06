import { Link } from 'react-router-dom'
import './ArtistCard.css'

export default function ArtistCard({ artist }) {
  const artistId = artist.mbid || artist.id
  return (
    <Link to={`/artist/${artistId}`} className="artist-card card">
      {artist.image_url && (
        <img className="artist-card-photo" src={artist.image_url} alt={artist.name} loading="lazy" />
      )}
      <div className="artist-header">
        <h3>{artist.name}</h3>
        <span className="badge primary">{artist.type || 'Artist'}</span>
      </div>

      <div className="artist-info">
        {artist.country && (
          <p><strong>Country:</strong> {artist.country}</p>
        )}

        {(artist.beginDate || artist['life-span']?.begin) && (
          <p><strong>Since:</strong> {artist.beginDate || artist['life-span']?.begin}</p>
        )}

        {artist.disambiguation && (
          <p className="disambiguation">{artist.disambiguation}</p>
        )}
      </div>

      <div className="artist-meta">
        <small>ID: {artistId.slice(0, 8)}...</small>
      </div>
    </Link>
  )
}
