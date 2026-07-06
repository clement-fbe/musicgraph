import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { artistAPI } from '../api'
import './Page.css'

export default function Stats() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await artistAPI.getStats()
        setStats(response.data)
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    fetchStats()
  }, [])

  const cards = stats
    ? [
        { label: 'Artists', value: stats.imported_artists },
        { label: 'Recordings', value: stats.recordings },
        { label: 'Albums', value: stats.albums },
        { label: 'Collaborations', value: stats.collaborations },
      ]
    : []

  const top = stats?.top_collaborators || []

  return (
    <div className="page-content">
      <div className="container">
        <h1>📊 Statistics</h1>

        {loading && <div className="loading">Loading statistics...</div>}

        {!loading && stats && (
          <div>
            <div className="stats-grid">
              {cards.map((c) => (
                <div key={c.label} className="stat-card card">
                  <h3>{c.label}</h3>
                  <p className="stat-number">{c.value}</p>
                </div>
              ))}
            </div>

            <section className="card" style={{ marginTop: '2rem' }}>
              <h2>🤝 Most connected artists</h2>
              {top.length > 0 ? (
                <div className="rank-list">
                  {top.map((a, i) => (
                    <div
                      key={a.mbid}
                      className="rank-row"
                      onClick={() => navigate(`/artist/${a.mbid}`)}
                    >
                      <span className="rank-num">{i + 1}</span>
                      {a.image_url ? (
                        <img className="rank-avatar" src={a.image_url} alt={a.name} loading="lazy" />
                      ) : (
                        <span className="rank-avatar rank-avatar-placeholder">🎤</span>
                      )}
                      <span className="rank-name">{a.name}</span>
                      <span className="rank-count">
                        {a.collaborators} collaborator{a.collaborators !== 1 ? 's' : ''}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="empty">No collaborations yet. Import and explore an artist to build the graph.</p>
              )}
            </section>
          </div>
        )}
      </div>

      <style>{`
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2rem;
        }

        .stat-card {
          text-align: center;
        }

        .stat-card h3 {
          color: var(--text-muted);
          margin-bottom: 1rem;
          text-transform: uppercase;
          font-size: 0.8rem;
          letter-spacing: 0.08em;
        }

        .stat-number {
          margin: 0;
          font-size: 2.75rem;
          font-weight: 800;
          color: var(--green);
        }

        .rank-list {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
          margin-top: 1rem;
        }

        .rank-row {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 0.6rem 0.75rem;
          border-radius: 0.5rem;
          cursor: pointer;
          transition: background-color 0.2s;
        }

        .rank-row:hover {
          background-color: var(--bg-elevated-hover);
        }

        .rank-num {
          width: 1.5rem;
          text-align: center;
          color: var(--text-muted);
          font-weight: 700;
        }

        .rank-avatar {
          width: 44px;
          height: 44px;
          border-radius: 50%;
          object-fit: cover;
          flex-shrink: 0;
        }

        .rank-avatar-placeholder {
          display: flex;
          align-items: center;
          justify-content: center;
          background: var(--bg-elevated-hover);
          font-size: 1.2rem;
        }

        .rank-name {
          flex: 1;
          font-weight: 600;
          min-width: 0;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .rank-count {
          color: var(--text-muted);
          font-size: 0.9rem;
          white-space: nowrap;
        }
      `}</style>
    </div>
  )
}
