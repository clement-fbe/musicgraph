import { NavLink, Link } from 'react-router-dom'
import './Header.css'

const links = [
  { to: '/', label: 'Home', icon: '🏠', end: true },
  { to: '/search', label: 'Search', icon: '🔍' },
  { to: '/artists', label: 'Your Library', icon: '📚' },
  { to: '/stats', label: 'Stats', icon: '📊' },
]

export default function Header() {
  return (
    <aside className="sidebar">
      <Link to="/" className="logo">
        <span className="logo-mark">🎵</span>
        <span className="logo-text">MusicGraph</span>
      </Link>

      <nav className="nav">
        {links.map((l) => (
          <NavLink
            key={l.to}
            to={l.to}
            end={l.end}
            className={({ isActive }) => 'nav-item' + (isActive ? ' active' : '')}
          >
            <span className="nav-icon">{l.icon}</span>
            <span>{l.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <p>Powered by Spotify &amp; Neo4j</p>
      </div>
    </aside>
  )
}
