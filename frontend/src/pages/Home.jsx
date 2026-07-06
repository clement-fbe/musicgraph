import { useNavigate } from 'react-router-dom'
import './Page.css'

export default function Home() {
  const navigate = useNavigate()

  return (
    <div className="page-content">
      <div className="hero">
        <h1>🎵 Explore Music Collaborations</h1>
        <p>Discover how artists collaborate and create music together</p>
        <p className="subtitle">Powered by the Spotify API & Neo4j Graph Database</p>

        <div className="cta-buttons">
          <button className="btn-primary" onClick={() => navigate('/search')}>
            Search Artists
          </button>
          <button className="btn-secondary" onClick={() => navigate('/artists')}>
            Browse All
          </button>
        </div>
      </div>

      <div className="features">
        <div className="feature card">
          <h3>🔍 Search</h3>
          <p>Find any artist from the Spotify catalog</p>
        </div>

        <div className="feature card">
          <h3>📊 Graph</h3>
          <p>Visualize artist collaborations and relationships</p>
        </div>

        <div className="feature card">
          <h3>🎼 Recordings</h3>
          <p>Explore songs and see who collaborated on them</p>
        </div>

        <div className="feature card">
          <h3>🤝 Collaborations</h3>
          <p>Discover who works together frequently</p>
        </div>
      </div>

      <div className="info-section">
        <h2>How it works</h2>
        <ol>
          <li>Search for an artist</li>
          <li>View their recordings and collaborators</li>
          <li>Explore the collaboration graph</li>
          <li>Discover new music through connections</li>
        </ol>
      </div>
    </div>
  )
}
