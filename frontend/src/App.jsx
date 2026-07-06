import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Header from './components/Header'
import Home from './pages/Home'
import Search from './pages/Search'
import Artists from './pages/Artists'
import ArtistDetail from './pages/ArtistDetail'
import Graph from './pages/Graph'
import Stats from './pages/Stats'
import './App.css'

function App() {
  return (
    <Router>
      <div className="app-layout">
        <Header />
        <div className="main-area">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/search" element={<Search />} />
            <Route path="/artists" element={<Artists />} />
            <Route path="/artist/:mbid" element={<ArtistDetail />} />
            <Route path="/graph/:mbid" element={<Graph />} />
            <Route path="/stats" element={<Stats />} />
          </Routes>
          <footer className="footer">
            <p>🎵 MusicGraph — Explore music collaborations with Spotify &amp; Neo4j</p>
          </footer>
        </div>
      </div>
    </Router>
  )
}

export default App
