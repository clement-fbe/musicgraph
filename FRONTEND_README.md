# MusicGraph Frontend — React + Vite

## Overview

Modern React 18 frontend for MusicGraph, built with Vite for fast development experience.

**Tech Stack:**
- React 18
- Vite (fast build tool)
- React Router v6 (navigation)
- Axios (API calls)
- CSS3 (styling)

## Features

### Pages

1. **Home** — Welcome page with features overview
2. **Search** — Find and import artists from MusicBrainz
3. **Artists** — Browse all imported artists
4. **Artist Detail** — View artist info, recordings, and collaborators
5. **Stats** — Database statistics and insights

### Components

- `Header` — Navigation bar with logo
- `ArtistCard` — Reusable artist display component

## Development

### Prerequisites

- Node.js 18+ (required for Vite)
- Backend running on `http://localhost:8000`
- Neo4j running on `localhost:7687`

### Installation & Setup

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (http://localhost:3000)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Development Server

The dev server includes:
- Hot Module Replacement (HMR) — instant reload on code changes
- Fast Vite bundling
- API proxy to backend (all `/api/*` requests forward to `http://localhost:8000`)

### API Integration

All API calls use the `api.js` module:

```javascript
import { artistAPI } from './api'

// Search artists
const results = await artistAPI.search('Daft Punk')

// Import artist
await artistAPI.import(mbid)

// Get artist details
const details = await artistAPI.getById(mbid)

// Get collaborations
const collabs = await artistAPI.getCollaborations(mbid)
```

## Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── Header.jsx
│   │   ├── Header.css
│   │   ├── ArtistCard.jsx
│   │   └── ArtistCard.css
│   ├── pages/
│   │   ├── Home.jsx
│   │   ├── Search.jsx
│   │   ├── Artists.jsx
│   │   ├── ArtistDetail.jsx
│   │   ├── ArtistDetail.css
│   │   ├── Stats.jsx
│   │   └── Page.css
│   ├── api.js
│   ├── App.jsx
│   ├── App.css
│   ├── main.jsx
│   └── index.css
├── index.html
├── vite.config.js
├── package.json
└── Dockerfile
```

## Styling

### Design System

Uses CSS variables for consistency:

```css
--primary: #1f2937 (dark gray)
--secondary: #3b82f6 (blue)
--accent: #10b981 (green)
--danger: #ef4444 (red)
--light: #f3f4f6 (light gray)
--border: #e5e7eb (border color)
```

### Responsive Design

Mobile-first approach with breakpoints at 768px.

All components are responsive and work on:
- Mobile (320px+)
- Tablet (768px+)
- Desktop (1200px+)

## Docker

Build and run with Docker Compose:

```bash
# From project root
docker compose up --build

# Frontend will be available at http://localhost:3000
```

## Troubleshooting

### "Cannot find module" errors

```bash
# Clear node_modules and reinstall
rm -r node_modules package-lock.json
npm install
```

### Port 3000 already in use

Edit `vite.config.js` and change the port:

```javascript
server: {
  port: 3001,  // Change this
}
```

### Backend API not responding

1. Check backend is running: `http://localhost:8000/api/health`
2. Verify Vite proxy in `vite.config.js`
3. Check CORS issues in browser console

### Slow build times

1. Ensure you're running Node.js 18+
2. Clear Vite cache: `rm -r node_modules/.vite`
3. Update dependencies: `npm update`

## Performance Tips

- Uses React.StrictMode for development checks
- Code splitting via React Router
- CSS modules could be added for better performance
- Consider adding React.memo for expensive components

## Future Improvements

1. **Graph Visualization** — Add D3.js or Cytoscape for collaboration graphs
2. **Advanced Search** — Filters by country, date, genre
3. **Collaborative Features** — Playlists, sharing
4. **Analytics** — Artist trends, collaboration patterns
5. **Authentication** — User accounts and saved preferences

## Common Commands

```bash
# Development
npm run dev          # Start dev server with HMR

# Production
npm run build        # Build optimized production bundle
npm run preview      # Preview production build locally

# Docker
docker compose up    # Start all services (neo4j, backend, frontend)
docker compose down  # Stop all services
```

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)

Requires modern JavaScript (ES2020+). Older browsers not supported.

---

**Created:** Part 4 of MusicGraph TP
**Last Updated:** 2026-06-25
