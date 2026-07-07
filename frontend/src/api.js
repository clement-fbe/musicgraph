import axios from 'axios'

const API_BASE = 'https://musicgraph.alwaysdata.net/api'

// Default client for quick requests
const api = axios.create({
  baseURL: API_BASE,
  timeout: 10000,
})

// Long-running operations client (import, enrich)
const apiLongTimeout = axios.create({
  baseURL: API_BASE,
  timeout: 60000, // 60 seconds for slow operations
})

export const artistAPI = {
  search: (query) => api.get('/search/artists', { params: { q: query } }),
  // Send the full artist data so the backend doesn't need to re-fetch from
  // MusicBrainz (which is rate-limited and unreliable from the container).
  import: (artist) =>
    apiLongTimeout.post('/import/artists', {
      mbid: artist.mbid || artist.id,
      name: artist.name,
      country: artist.country || null,
      type: artist.type || null,
      disambiguation: artist.disambiguation || null,
      begin_date: artist.beginDate || artist['life-span']?.begin || null,
    }),
  enrich: (mbid) => apiLongTimeout.post('/enrich/artists', { mbid, fetch_recordings: true }), // Long timeout
  // Enrich with Spotify data (photo + album covers). No-op if no Spotify key.
  enrichSpotify: (mbid) => apiLongTimeout.post('/enrich/spotify', { mbid }),
  getAll: () => api.get('/artists'),
  getById: (mbid) => api.get(`/artists/${mbid}`),
  getCollaborations: (mbid) => api.get(`/artists/${mbid}/collaborations`),
  getGraph: (mbid) => api.get(`/graph/${mbid}`),
  getStats: () => api.get('/stats'),
}

export const spotifyAPI = {
  status: () => api.get('/spotify/status'),
}

export const recordingAPI = {
  create: (recordingMbid, recordingName, artistMbid, lengthMs) =>
    api.post('/recordings', {
      recording_mbid: recordingMbid,
      recording_name: recordingName,
      artist_mbid: artistMbid,
      length_ms: lengthMs,
    }),
}

export const collaborationAPI = {
  detect: (artist1Mbid, artist2Mbid) =>
    api.post('/collaborations/detect', {
      artist1_mbid: artist1Mbid,
      artist2_mbid: artist2Mbid,
    }),
}

export const healthAPI = {
  check: () => api.get('/health'),
}
