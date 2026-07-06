import { useEffect, useState } from 'react'
import { artistAPI } from '../api'
import ArtistCard from '../components/ArtistCard'
import './Page.css'

export default function Artists() {
  const [artists, setArtists] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchArtists = async () => {
      try {
        const response = await artistAPI.getAll()
        setArtists(response.data.artists || [])
      } catch (err) {
        setError('Failed to load artists')
        console.error(err)
      } finally {
        setLoading(false)
      }
    }

    fetchArtists()
  }, [])

  return (
    <div className="page-content">
      <div className="container">
        <h1>🎤 All Artists</h1>

        {error && <div className="error">{error}</div>}

        {loading && <div className="loading">Loading artists...</div>}

        {artists.length > 0 && (
          <div>
            <p className="results-info">{artists.length} artists in database</p>
            <div className="grid">
              {artists.map((artist) => (
                <ArtistCard key={artist.mbid} artist={artist} />
              ))}
            </div>
          </div>
        )}

        {!loading && artists.length === 0 && (
          <div className="card">
            <p>No artists found. Start by searching and importing artists!</p>
          </div>
        )}
      </div>
    </div>
  )
}
