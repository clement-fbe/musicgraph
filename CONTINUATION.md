# MusicGraph — Contexte de Continuation

**Date : 2026-06-25**
**Statut : Partie 2 (Backend) fiabilisée et testée. Prêt pour Partie 3 (Relations).**

---

## 🎯 Résumé rapide

**Ce qui a été fait :**
- ✅ Partie 1 — Analyse & Design (complète)
- ✅ Partie 2 — Backend fiabilisé avec retry + mock fallback
- ✅ Neo4j persistence testée (artiste Daft Punk importé)
- ✅ Architecture documentée

**Ce qui reste :**
- Partie 3 — Collaborations & Relations (À COMMENCER)
- Partie 4 — API interne complète (À FAIRE)
- Partie 5 — Frontend React (À FAIRE)
- Partie 6 — Docker, docs, données (À FAIRE)

---

## 📁 Fichiers critiques à consulter

### Pour reprendre immédiatement :

1. **`claude.md`** — Contexte complet du projet
   - Objectifs, modèle de données, découpage 6 parties
   - À lire en premier pour comprendre la vision

2. **`docs/design.md`** — Architecture système
   - Diagramme client-serveur
   - Modèle Neo4j complet (nœuds + relations)
   - Flux de données import/requête

3. **`docs/oral_presentation.md`** — Journal d'exécution
   - Résumé Partie 1 & 2
   - Commandes testées, résultats
   - Problèmes rencontrés & solutions

4. **`plan-action.md`** — Découpage des 6 parties
   - Plan détaillé pour Partie 3, 4, 5, 6

### Backend (Partie 2 — FONCTIONNEL) :

5. **`backend/app/main.py`**
   - 3 endpoints opérationnels :
     - `GET /api/health` ✅
     - `GET /api/search/artists?q=...` ✅ (retry + mock fallback)
     - `POST /api/import/artists` ✅ (retry + mock fallback)
   - Endpoints à ajouter (Partie 4) : `/api/artists`, `/api/recordings`, `/api/collaborations`, `/api/graph`, `/api/stats`

6. **`backend/app/neo4j_client.py`**
   - Singleton driver pattern
   - Fonction `create_or_update_artist()` (MERGE)
   - À augmenter : funcs pour Recording, Release, Relationships

7. **`backend/app/musicbrainz_mock.py`**
   - Mock data : Daft Punk (MBID: 056e4f3e-d505-4dad-8ec1-d04f521cbb56)
   - À augmenter : plus d'artistes pour tests collaboration

8. **`backend/requirements.txt`**
   - Dépendances stables (fastapi, uvicorn, httpx, neo4j)

9. **`backend/Dockerfile`**
   - Image Python 3.12-slim avec ca-certificates

### Config & Orchestration :

10. **`.env.example`**
    - Variables : `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`, `MUSICBRAINZ_BASE`, `MUSICBRAINZ_USER_AGENT`

11. **`docker-compose.yml`**
    - 2 services : neo4j (7687), backend (8000)
    - À ajouter : frontend (3000)

---

## 🚀 Commandes essentielles

### Démarrer le stack complet
```powershell
cd c:\Users\codcl\Documents\B+3Ynov\NoSQL
docker compose down
docker compose build
docker compose up -d
Start-Sleep -Seconds 3
docker compose logs backend --tail 20
```

### Tester les endpoints (Partie 2)
```powershell
# Santé
Invoke-RestMethod -Uri 'http://localhost:8000/api/health'

# Recherche
$search = (Invoke-WebRequest -Uri 'http://localhost:8000/api/search/artists?q=Daft%20Punk' -UseBasicParsing).Content | ConvertFrom-Json
$mbid = $search.artists[0].id

# Import
$import = Invoke-RestMethod -Uri 'http://localhost:8000/api/import/artists' -Method POST `
  -ContentType 'application/json' -Body (ConvertTo-Json @{mbid=$mbid})

# Vérifier Neo4j
docker exec musicgraph-neo4j cypher-shell -u neo4j -p "change-me" `
  "MATCH (a:Artist) RETURN a LIMIT 5"
```

### Logs utiles
```powershell
docker compose logs backend --tail 50
docker compose logs neo4j --tail 20
docker exec musicgraph-neo4j cypher-shell -u neo4j -p "change-me" "MATCH (a:Artist) RETURN COUNT(a)"
```

---

## 📋 Prochaines étapes — Partie 3 (Collaborations)

### Étape 3.1 : Enrichir l'import MusicBrainz

**Dans `backend/app/main.py`**, ajouter endpoints pour récupérer :
- Enregistrements (`/artist/{mbid}/recordings`)
- Releases/Albums (`/artist/{mbid}/releases`)
- Artistes liés (`/artist/{mbid}/relationships` pour collaborations)

**Exemple Cypher à implémenter :**
```cypher
// Créer Recording node
MERGE (r:Recording {mbid: $mbid})
SET r.name = $name, r.length_ms = $length
RETURN r

// Créer relation PERFORMED
MATCH (a:Artist {mbid: $artist_mbid})
MATCH (r:Recording {mbid: $recording_mbid})
CREATE (a)-[:PERFORMED {position: $pos}]->(r)

// Détecter collaboration (même recording)
MATCH (a1:Artist)-[:PERFORMED]-(r:Recording)-(a2:Artist)
WHERE a1.mbid < a2.mbid
MERGE (a1)-[c:COLLABORATED_WITH]-(a2)
ON CREATE SET c.count = 1, c.recordings = [$r.mbid]
ON MATCH SET c.count = c.count + 1, c.recordings = c.recordings + [$r.mbid]
```

### Étape 3.2 : Ajouter Neo4j queries pour collaborations

**Dans `backend/app/neo4j_client.py`**, implémenter :
- `get_artist_recordings(mbid)` — Retourne recordings d'un artiste
- `get_artist_collaborators(mbid)` — Retourne artistes qui ont collaboré
- `create_recording_node()` — MERGE Recording
- `create_release_node()` — MERGE Release
- `create_relationships()` — PERFORMED, APPEARS_ON, etc.

### Étape 3.3 : Endpoint d'import collaborations

**Dans `backend/app/main.py`**, ajouter :
```python
@app.post("/api/import/artists/{mbid}/collaborations")
async def import_collaborations(mbid: str):
    """
    1. Récupère tous les recordings de l'artiste
    2. Pour chaque recording, find les autres artistes
    3. Crée relations COLLABORATED_WITH
    """
```

### Étape 3.4 : Endpoint de requête collaborations

**Dans `backend/app/main.py`**, ajouter :
```python
@app.get("/api/artists/{mbid}/collaborations")
async def get_collaborations(mbid: str):
    """
    Retourne tous les artistes qui ont collaboré
    avec requête Cypher à Neo4j
    """
```

---

## 💾 État de la base Neo4j

**Actuellement :**
- 1 artiste : Daft Punk (056e4f3e-d505-4dad-8ec1-d04f521cbb56)
- Propriétés : name, type, country, beginDate, disambiguation, mbid
- Aucune relation ni Recording/Release encore

**À ajouter pour Partie 3 :**
- Recording nodes (morceaux de Daft Punk)
- Release nodes (albums de Daft Punk)
- Relations : PERFORMED, APPEARS_ON
- Artistes collaborateurs + relations COLLABORATED_WITH

---

## 🔧 Points techniques importants

### Retry Logic (DÉJÀ IMPLÉMENTÉ)
- 3 tentatives max
- Exponential backoff : 0.5s, 1.0s, 1.5s
- Fallback à mock data si tous les retry échouent
- Logs INFO/WARNING pour tracer source (real vs mock)

### Mock Data (DÉJÀ EN PLACE)
- Daft Punk complet
- Beyoncé simplifié
- À augmenter : ajouter Stromae, Jay-Z, etc. si besoin tests

### Neo4j MERGE Pattern
```cypher
MERGE (a:Artist {mbid: $mbid})
SET a.name = $name, a.country = $country, ...
RETURN a
```
- Crée si n'existe pas
- Update si existe (idempotent)
- Évite doublons via clé unique (mbid)

### Connexion MusicBrainz
- **Base URL** : `http://musicbrainz.org/ws/2` (HTTP, pas HTTPS)
- **User-Agent** : Obligatoire, lire de `.env`
- **Rate Limit** : ~1 requête/sec recommandé
- **Format** : `?fmt=json` pour JSON

---

## 📚 Documentation à consulter

- `README.md` — Description projet (cahier des charges)
- `claude.md` — Vue globale, modèle données
- `docs/design.md` — Architecture détaillée
- `docs/oral_presentation.md` — Exécution Partie 1 & 2
- `plan-action.md` — Découpage 6 parties

---

## ⚠️ Pièges à éviter

1. **Oublier User-Agent MusicBrainz** → API bloque
2. **Oublier MERGE en Cypher** → Créer doublons Artist
3. **Faire requêtes async MusicBrainz dans asyncio sans to_thread** → Protocol errors
4. **Oublier parametrer requêtes Cypher** → Injection risk
5. **Ne pas vérifier les tests après rebuild Docker** → Erreurs invisible

---

## ✅ Checklist avant Partie 3

- [ ] Lire `claude.md` pour contexte complet
- [ ] Consulter `docs/design.md` pour modèle Neo4j
- [ ] Vérifier que backend + Neo4j démarrent : `docker compose up -d --build`
- [ ] Tester endpoint santé : `GET /api/health` → 200 OK
- [ ] Tester import : Daft Punk importé dans Neo4j
- [ ] Consulter `docs/oral_presentation.md` pour résumé exécution
- [ ] Prêt ? Commencer Partie 3 !

---

## 📊 Progress global

```
Partie 1 (Design)              [████████████████] 100% ✅
Partie 2 (Backend Import)      [████████████████] 100% ✅
Partie 3 (Collaborations)      [░░░░░░░░░░░░░░░░]   0% ⏳ À COMMENCER
Partie 4 (API interne)         [░░░░░░░░░░░░░░░░]   0%
Partie 5 (Frontend)            [░░░░░░░░░░░░░░░░]   0%
Partie 6 (Docker/Docs/Data)    [░░░░░░░░░░░░░░░░]   0%
```

---

**Bon courage pour la Partie 3 ! 🚀**
