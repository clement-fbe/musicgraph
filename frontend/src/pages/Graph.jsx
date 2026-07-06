import { useState, useEffect, useRef } from 'react'
import { useParams } from 'react-router-dom'
import cytoscape from 'cytoscape'
import { artistAPI } from '../api'
import './Page.css'

export default function Graph() {
  const { mbid } = useParams()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [graphData, setGraphData] = useState(null)
  const cyRef = useRef(null)
  const containerRef = useRef(null)

  useEffect(() => {
    const fetchGraph = async () => {
      if (!mbid) return

      setLoading(true)
      setError('')

      try {
        console.log('📊 Fetching graph for:', mbid)
        const response = await artistAPI.getGraph(mbid)
        console.log('✅ Graph data received:', response.data)
        setGraphData(response.data.graph)
      } catch (err) {
        console.error('❌ Error fetching graph:', err)
        setError('Failed to load graph')
      } finally {
        setLoading(false)
      }
    }

    fetchGraph()
  }, [mbid])

  // Initialize Cytoscape when graph data is ready
  useEffect(() => {
    if (!graphData || !containerRef.current) return

    const elements = []

    // Add nodes — the first node is the central artist (added first by the backend)
    // We display the FULL title (wrapped over several lines) so versions like
    // "Aerodynamic (remix)" and "Aerodynamic (official video)" are distinguishable.
    graphData.nodes?.forEach((node, idx) => {
      const baseClass = node.type?.toLowerCase().replace(/\s+/g, '-') || 'artist'
      elements.push({
        data: {
          id: node.id,
          label: node.name || '',
          fullLabel: node.name,
          type: node.type,
        },
        classes: idx === 0 ? `${baseClass} central` : baseClass,
      })
    })

    // Add edges
    graphData.edges?.forEach((edge, idx) => {
      elements.push({
        data: {
          id: `edge-${idx}`,
          source: edge.from,
          target: edge.to,
          label: edge.type,
          type: edge.type,
        },
        classes: edge.type?.toLowerCase().replace(/\s+/g, '-'),
      })
    })

    const style = [
      {
        selector: 'node',
        style: {
          'content': 'data(label)',
          'text-valign': 'bottom',
          'text-halign': 'center',
          'text-margin-y': '5px',
          'background-color': '#1db954',
          'color': '#ffffff',
          'font-size': '13px',
          'font-weight': 'normal',
          'border-width': '0px',
          'border-color': '#121212',
          'width': '42px',
          'height': '42px',
          'text-wrap': 'wrap',
          'text-max-width': '150px',
          'min-zoomed-font-size': 0,
        },
      },
      {
        selector: 'node.artist',
        style: {
          'background-color': '#1db954',
          'width': '54px',
          'height': '54px',
          'font-size': '15px',
          'font-weight': 'bold',
        },
      },
      {
        selector: 'node.central',
        style: {
          'background-color': '#1ed760',
          'width': '90px',
          'height': '90px',
          'font-size': '18px',
          'font-weight': 'bold',
          'color': '#000',
          'text-valign': 'center',
          'text-margin-y': '0px',
          'z-index': 10,
        },
      },
      {
        selector: 'node.recording',
        style: {
          'background-color': '#b3b3b3',
          'width': '40px',
          'height': '40px',
          'font-size': '12px',
        },
      },
      {
        selector: 'node.release',
        style: {
          'background-color': '#f59e0b',
          'width': '46px',
          'height': '46px',
        },
      },
      {
        selector: 'edge',
        style: {
          'line-color': '#535353',
          'target-arrow-color': '#535353',
          'target-arrow-shape': 'triangle',
          'arrow-scale': 0.7,
          'width': '1px',
          'curve-style': 'haystack',
          'opacity': 0.5,
        },
      },
      {
        selector: 'edge.collaborated-with',
        style: {
          'line-color': '#f59e0b',
          'target-arrow-shape': 'none',
          'width': '3px',
          'opacity': 0.9,
          'curve-style': 'bezier',
        },
      },
      // Highlight the connections of whatever node is selected
      {
        selector: 'node:selected',
        style: {
          'background-color': '#ef4444',
          'border-color': '#b91c1c',
          'border-width': '3px',
          'font-weight': 'bold',
          'z-index': 20,
        },
      },
      {
        selector: 'edge:selected',
        style: {
          'line-color': '#ef4444',
          'target-arrow-color': '#ef4444',
          'width': '3px',
          'opacity': 1,
          'label': 'data(label)',
          'font-size': '9px',
          'color': '#374151',
          'text-background-color': '#fff',
          'text-background-opacity': 1,
          'text-background-padding': '2px',
        },
      },
    ]

    const cy = cytoscape({
      container: containerRef.current,
      elements: elements,
      style: style,
      layout: {
        name: 'concentric',
        // Central artist in the middle, everything else on rings around it
        concentric: (node) => (node.hasClass('central') ? 10 : node.hasClass('artist') ? 5 : 1),
        levelWidth: () => 1,
        minNodeSpacing: 55,
        spacingFactor: 0.9,
        animate: true,
        animationDuration: 500,
        avoidOverlap: true,
      },
      minZoom: 0.2,
      maxZoom: 3,
    })

    // Click a node to highlight it and its direct connections
    cy.on('tap', 'node', (evt) => {
      const node = evt.target
      cy.elements().removeClass('faded')
      const neighborhood = node.closedNeighborhood()
      cy.elements().not(neighborhood).addClass('faded')
    })

    // Click on empty space to reset the highlight
    cy.on('tap', (evt) => {
      if (evt.target === cy) {
        cy.elements().removeClass('faded')
      }
    })

    // Style for faded (non-highlighted) elements
    cy.style().selector('.faded').style({ 'opacity': 0.12 }).update()

    // Fit graph to view
    cy.fit(cy.elements(), 40)

    cyRef.current = cy

    // Cleanup
    return () => {
      cy.destroy()
    }
  }, [graphData])

  return (
    <div className="page-content">
      <div className="container">
        <h1>🎵 Artist Collaboration Graph</h1>

        {loading && <div className="loading">Loading graph...</div>}

        {error && <div className="error">{error}</div>}

        {graphData && (
          <>
            <div className="graph-info">
              <p>
                Showing <strong>{graphData.nodes?.length || 0}</strong> nodes and{' '}
                <strong>{graphData.edges?.length || 0}</strong> relationships
              </p>
              <div className="legend">
                <div className="legend-item">
                  <span className="dot artist"></span> Artist
                </div>
                <div className="legend-item">
                  <span className="dot recording"></span> Recording
                </div>
                <div className="legend-item">
                  <span className="dot release"></span> Release
                </div>
              </div>
            </div>

            <div className="cytoscape-wrapper" ref={containerRef} style={{ height: '650px', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px', background: '#181818' }}></div>

            <div className="graph-controls">
              <p>💡 Click a node to highlight its connections • Click empty space to reset • Scroll to zoom • Drag to pan</p>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
