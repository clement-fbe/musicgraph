# Architecture & Design — MusicGraph

## 1. Vue d'ensemble

MusicGraph est une application web permettant d'explorer les collaborations musicales à partir de l'API MusicBrainz et d'une base de données graphe Neo4j.

**Stack technique choisi :**
- **Backend** : Python 3.12 + FastAPI
- **Frontend** : React 18 + Vite (JavaScript/JSX)
- **Base de données** : Neo4j 5.12 (graphe)
- **Orchestration** : Docker Compose
- **API externe** : MusicBrainz (http://musicbrainz.org/ws/2)

---

## 2. Architecture générale

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Web (React)                       │
│                     (port 3000)                             │
└────────────────────────────┬────────────────────────────────┘
                             │
                    HTTP/REST API
                             │
┌────────────────────────────▼────────────────────────────────┐
│              Backend FastAPI (Python)                       │
│              (port 8000, uvicorn)                           │
│                                                              │
│  ├─ GET /api/health                                        │
│  ├─ GET /api/search/artists?q=...                          │
│  ├─ POST /api/import/artists (mbid)                        │
│  ├─ GET /api/artists                                       │
│  ├─ GET /api/artists/{id}                                  │
│  ├─ GET /api/artists/{id}/recordings                       │
│  ├─ GET /api/artists/{id}/collaborations                   │
│  ├─ GET /api/graph/{artist_id}                             │
│  └─ GET /api/stats                                         │
└────────────────────────────┬────────────────────────────────┘
         │                        │
         │ Cypher Queries         │ MusicBrainz API
         │ (bolt://neo4j:7687)    │ (http://musicbrainz.org/ws/2)
         │                        │
┌────────▼────────┐      ┌────────▼────────────────────────┐
│   Neo4j Graph   │      │  MusicBrainz (External)         │
│   (port 7687)   │      │  - Recherche d'artistes         │
│                 │      │  - Détails artistes             │
│ - Artist nodes  │      │  - Enregistrements & releases   │
│ - Recording     │      │  - Collaborations              │
│ - Release       │      │  - Genre, zone                 │
│ - Relation      │      │  - Métadonnées                 │
│ - Genre         │      └─────────────────────────────────┘
│ - Area          │
└─────────────────┘
```

---

## 3. Modèle de données Neo4j

### 3.1 Nœuds

#### Artist
```cypher
(:Artist {
  mbid: String,           // Identifiant unique MusicBrainz
  name: String,           // Nom de l'artiste
  sort_name: String,      // Nom pour tri (optionnel)
  type: String,           // "Person", "Group", "Orchestra", etc.
  country: String,        // Code ISO (FR, US, UK, etc.)
  beginDate: String,      // "YYYY" ou "YYYY-MM-DD"
  endDate: String,        // Optionnel
  disambiguation: String, // Description pour différencier
  img_url: String,        // Optionnel, lien cover art
  created_at: DateTime    // Timestamp d'import
})
```

#### Recording / Track
```cypher
(:Recording {
  mbid: String,        // ID MusicBrainz
  name: String,        // Titre du morceau
  length_ms: Integer,  // Durée en millisecondes
  created_at: DateTime
})
```

#### Release / Album
```cypher
(:Release {
  mbid: String,         // ID MusicBrainz
  name: String,         // Nom de l'album
  release_date: String, // "YYYY-MM-DD"
  type: String,         // "Album", "Single", "EP", etc.
  barcode: String,      // Optionnel
  created_at: DateTime
})
```

#### Label
```cypher
(:Label {
  mbid: String,
  name: String,
  country: String,
  created_at: DateTime
})
```

#### Genre
```cypher
(:Genre {
  name: String  // Ex: "Electronic", "Hip-Hop", "Rock"
})
```

#### Area
```cypher
(:Area {
  mbid: String,
  name: String,          // Ex: "France", "United States"
  type: String,          // "Country", "Region", "City", etc.
  created_at: DateTime
})
```

### 3.2 Relations

| Relation | Source | Target | Propriétés | Sens |
|----------|--------|--------|-----------|------|
| `PERFORMED` | Artist | Recording | `{position: int}` | Artiste a enregistré ce morceau |
| `FEATURED_ON` | Artist | Recording | `{credited_as: str}` | Artiste en featuring |
| `COLLABORATED_WITH` | Artist | Artist | `{count: int, recordings: []}` | Deux artistes ont collaboré |
| `APPEARS_ON` | Recording | Release | `{track_number: int}` | Morceau sur cet album |
| `RELEASED_BY` | Release | Label | `{catalog: str}` | Album édité par ce label |
| `FROM_AREA` | Artist | Area | `{}` | Artiste originaire de cette zone |
| `RELEASED_IN` | Release | Area | `{}` | Album sorti dans cette zone |
| `ASSOCIATED_WITH_GENRE` | Artist | Genre | `{}` | Artiste dans ce genre |

---

## 4. Flux de données

### 4.1 Flux d'import

```
Utilisateur
    │
    ├─→ Recherche "Daft Punk"
    │   ├─→ Backend appelle MusicBrainz /artist/
    │   ├─→ Retour 20+ résultats
    │   └─→ Frontend affiche liste
    │
    ├─→ Sélectionne Daft Punk (mbid: 056e4f3e-...)
    │   └─→ Clique "Importer"
    │
    ├─→ Backend récupère détails MusicBrainz
    │   ├─→ GET /artist/{mbid}
    │   ├─→ GET /artist/{mbid}/recordings
    │   ├─→ GET /artist/{mbid}/releases
    │   └─→ GET /artist/{mbid}/relationships (collaborations)
    │
    ├─→ Backend crée nœuds & relations dans Neo4j
    │   ├─→ MERGE (:Artist {mbid: "..."}) avec properties
    │   ├─→ CREATE (:Recording {...})
    │   ├─→ CREATE (:Release {...})
    │   ├─→ CREATE relation PERFORMED
    │   ├─→ CREATE relation APPEARS_ON
    │   ├─→ Détect collaborations → CREATE COLLABORATED_WITH
    │   └─→ CREATE Genre, Area nodes + relations
    │
    └─→ Frontend rafraîchit et affiche la fiche artiste
        └─→ Affiche morceaux, albums, collaborations
```

### 4.2 Flux de requête utilisateur

```
Utilisateur visite "Fiche artiste"
    │
    ├─→ Frontend appelle GET /api/artists/{id}
    │
    ├─→ Backend exécute Cypher queries :
    │   ├─→ MATCH (a:Artist {mbid: "..."}) RETURN a
    │   ├─→ MATCH (a)-[:PERFORMED]->(r:Recording) RETURN r
    │   ├─→ MATCH (a)-[:APPEARS_ON]-(album:Release) RETURN album
    │   ├─→ MATCH (a)-[:COLLABORATED_WITH]-(collab:Artist) RETURN collab
    │   ├─→ MATCH (a)-[:ASSOCIATED_WITH_GENRE]-(g:Genre) RETURN g
    │   └─→ MATCH (a)-[:FROM_AREA]-(area:Area) RETURN area
    │
    ├─→ Backend retourne JSON structuré
    │
    └─→ Frontend affiche tableau / visualisation
```

---

## 5. Considérations techniques

### 5.1 Gestion des doublons

- **Clé unique** : MBID de MusicBrainz
- **Stratégie** : `MERGE` en Cypher (crée si absent, update si existe)
- **Format** : Tous les nœuds clés (Artist, Recording, Release, Label, Area) utilisent `mbid` comme propriété unique

### 5.2 Gestion des données manquantes

- Propriétés optionnelles : `?:` en Cypher
- Vérification frontend : affichage "Non disponible" si absent
- Requête MusicBrainz : certains champs peuvent être `null`

### 5.3 Rate limiting MusicBrainz

- MusicBrainz limite les requêtes
- **Solution** : Mock data pour développement/test
- **Production** : Cache les réponses (Redis ou fichier local)
- **User-Agent** : Obligatoire dans headers

### 5.4 Performance Neo4j

- **Indexes** : Sur `mbid`, `name` pour recherches rapides
- **Pagination** : `LIMIT 50`, `OFFSET` pour gros résultats
- **Aggregation** : `count()`, `collect()` pour statistiques

---

## 6. Points de sécurité

- ✅ Neo4j avec authentification (neo4j/change-me, à modifier en prod)
- ✅ Backend ne expose que les endpoints nécessaires
- ✅ Paramétrage des requêtes Cypher (injection prevention)
- ✅ CORS configuré sur backend si frontend sur autre domaine
- ✅ `.env` stocke les secrets, `.env.example` expose la structure

---

## 7. Extensibilité

**Futures améliorations :**
- Recherche graphique avancée (chemins entre 2 artistes)
- Recommandations basées sur le graphe
- Mise à cache des données MusicBrainz
- Synchronisation périodique de la BD
- Export des graphes (JSON, GraphML, etc.)
- Analyse de réseaux (centralité, communautés)

---

## 8. Fichiers clés du projet

```
MusicGraph/
├── backend/
│   ├── app/
│   │   ├── main.py                 # FastAPI app & endpoints
│   │   ├── neo4j_client.py         # Connexion & requêtes Cypher
│   │   ├── musicbrainz_mock.py     # Données mock pour tests
│   │   └── __init__.py
│   ├── requirements.txt            # Dépendances Python
│   ├── Dockerfile                  # Image backend
│   └── .env                        # Variables locales
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Home.jsx
│   │   │   ├── Search.jsx
│   │   │   ├── ArtistDetail.jsx
│   │   │   ├── Graph.jsx
│   │   │   └── Stats.jsx
│   │   ├── components/
│   │   │   ├── ArtistCard.jsx
│   │   │   ├── RecordingList.jsx
│   │   │   └── CollaborationView.jsx
│   │   ├── App.jsx                 # Router principal
│   │   └── index.css
│   ├── package.json
│   ├── vite.config.js
│   └── Dockerfile
├── docs/
│   ├── oral_presentation.md        # Rendu pédagogique
│   └── design.md                   # Ce fichier
├── data/
│   ├── sample_import.json          # Exemple données
│   └── README.md                   # Instructions import
├── docker-compose.yml              # Orchestration
├── .env.example                    # Template env
├── README.md                       # Doc utilisateur
└── claude.md                       # Contexte du projet
```

---

## Résumé

MusicGraph utilise une architecture client-serveur classique avec un backend Python/FastAPI exposant une API REST et connecté à une base graphe Neo4j. Le frontend React affiche les artistes, relations et statistiques. L'import de données se fait via l'API MusicBrainz avec gestion des erreurs, retry, et mock data pour la résilience.

**Prêt pour la Partie 2+ ? Les fondations sont posées.** ✅
