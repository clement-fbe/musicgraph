import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { artistAPI } from '../api'
import ArtistCard from '../components/ArtistCard'
import './Page.css'

export default function Search() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [importing, setImporting] = useState(null)
  const [importSuccess, setImportSuccess] = useState('')
  const navigate = useNavigate()

  const handleSearch = async (e) => {
    e.preventDefault()
    if (!query.trim()) return

    setLoading(true)
    setError('')
    setResults([])

    console.log('🔍 Starting search for:', query)

    try {
      console.log('📡 Sending request to API...')
      const response = await artistAPI.search(query)

      console.log('✅ API Response received:', response)
      console.log('📊 Response data:', response.data)
      console.log('🎨 Artists in response:', response.data.artists)

      const artists = response.data.artists || []
      setResults(artists)

      if (artists.length === 0) {
        // Distinguish "Spotify not configured" from a genuine empty result.
        const msg = response.data.spotify_available === false
          ? 'Spotify is not configured on the server. Add SPOTIFY_CLIENT_ID / SECRET to the backend .env.'
          : 'No artists found. Try a different search term.'
        console.warn('⚠️', msg)
        setError(msg)
      } else {
        console.log(`✨ Found ${artists.length} artists`)
      }
    } catch (err) {
      console.error('❌ ERROR DETAILS:')
      console.error('  Status:', err.response?.status)
      console.error('  Status Text:', err.response?.statusText)
      console.error('  Data:', err.response?.data)
      console.error('  Message:', err.message)
      console.error('  Full error:', err)

      setError('Error searching artists. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleImport = async (artist) => {
    const artistId = artist.mbid || artist.id
    setImporting(artistId)
    setImportSuccess('')
    setError('')

    try {
      // 1. Import the artist (uses the data we already have — always reliable)
      console.log('📥 Importing artist:', artist.name)
      await artistAPI.import(artist)
      setImportSuccess(`${artist.name} imported! Fetching recordings...`)

      // 2. Enrich with recordings & collaborations (best-effort, may be slow)
      try {
        console.log('🎼 Enriching with recordings...')
        const enrichRes = await artistAPI.enrich(artistId)
        console.log('✅ Enriched:', enrichRes.data)
        setImportSuccess(
          `${artist.name} imported with ${enrichRes.data.recordings_added || 0} recordings!`
        )
      } catch (enrichErr) {
        // Enrichment failures are non-fatal — the artist is still imported
        console.warn('⚠️ Enrichment failed (artist still imported):', enrichErr)
        setImportSuccess(`${artist.name} imported successfully!`)
      }

      setTimeout(() => {
        navigate(`/artist/${artistId}`)
      }, 1000)
    } catch (err) {
      setError(`Failed to import ${artist.name}`)
      console.error(err)
    } finally {
      setImporting(null)
    }
  }

  return (
    <div className="page-content">
      <div className="container">
        <h1>🔍 Search Artists</h1>

        <form onSubmit={handleSearch} className="search-form">
          <div className="form-group">
            <input
              type="text"
              placeholder="Enter artist name (e.g., Daft Punk, The Beatles)..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="search-input"
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Searching...' : 'Search'}
            </button>
          </div>
        </form>

        {importSuccess && <div className="success">{importSuccess}</div>}
        {error && <div className="error">{error}</div>}

        {loading && <div className="loading">Searching...</div>}

        {results.length > 0 && (
          <div>
            <p className="results-info">Found {results.length} results</p>
            <div className="search-results">
              {results.map((artist) => (
                <div key={artist.id} className="search-result card">
                  <ArtistCard artist={artist} />
                  <button
                    onClick={() => handleImport(artist)}
                    disabled={importing === artist.id}
                    className="import-btn"
                  >
                    {importing === artist.id ? 'Importing...' : 'Import & Explore'}
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
