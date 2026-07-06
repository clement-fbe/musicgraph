# Plan d’action pour le TP MusicGraph

## 1. Analyse et design
- Lire le cahier des charges (`README.md`) et identifier les objectifs.
- Comprendre les notions NoSQL / graphes du PDF :
  - quand utiliser NoSQL,
  - concepts nœuds / relations / propriétés,
  - Cypher et Neo4j.
- Choisir la stack technique :
  - backend (Node / Python / etc.),
  - frontend (React / Vue / HTML/CSS simple),
  - Neo4j,
  - Docker.
- Modéliser le graphe attendu :
  - nœuds `Artist`, `Recording`/`Track`, `Release`/`Album`, `Label`, `Genre`, `Area`,
  - relations `PERFORMED`, `FEATURED_ON`, `COLLABORATED_WITH`, `APPEARS_ON`, `RELEASED_BY`, `ASSOCIATED_WITH_GENRE`, `FROM_AREA`, `RELEASED_IN`.
- Rédiger un plan de conception et une architecture générale.

## 2. Backend & import MusicBrainz
- Implémenter la recherche d’artistes via l’API MusicBrainz.
- Construire l’endpoint de recherche (`GET /api/search/artists`).
- Implémenter l’import d’un artiste dans Neo4j :
  - création ou mise à jour du nœud `Artist`,
  - détection et évitement des doublons via MBID.
- Ajouter l’import des enregistrements associés (`Recording`/`Track`).
- Ajouter l’import des releases / albums.
- Ajouter l’import des labels, genres et zones géographiques si disponibles.

## 3. Relations et détection des collaborations
- Détecter les collaborations sur un même morceau ou release.
- Repérer les featuring à partir des crédits ou titres (`feat.`, `x`, `&`, `avec`, etc.).
- Créer les relations Neo4j :
  - `(:Artist)-[:PERFORMED]->(:Recording)`,
  - `(:Artist)-[:FEATURED_ON]->(:Recording)`,
  - `(:Artist)-[:COLLABORATED_WITH]->(:Artist)`,
  - `(:Recording)-[:APPEARS_ON]->(:Release)`,
  - `(:Release)-[:RELEASED_BY]->(:Label)`,
  - `(:Artist)-[:ASSOCIATED_WITH_GENRE]->(:Genre)`,
  - `(:Artist)-[:FROM_AREA]->(:Area)`,
  - `(:Release)-[:RELEASED_IN]->(:Area)`.
- Vérifier la qualité des données :
  - normalisation,
  - gestion des données manquantes,
  - limitation des appels MusicBrainz,
  - gestion des erreurs API.

## 4. API interne
- Implémenter les endpoints de données Neo4j :
  - `GET /api/artists`
  - `GET /api/artists/:id`
  - `GET /api/artists/:id/recordings`
  - `GET /api/artists/:id/releases`
  - `GET /api/artists/:id/collaborations`
  - `POST /api/import/artists`
  - `GET /api/recordings`, `GET /api/releases`, `GET /api/graph`, `GET /api/stats/...`
- S’assurer que le frontend peut consommer toutes les données nécessaires.
- Ajouter des tests ou des vérifications simples des endpoints.

## 5. Frontend et visualisation
- Construire les pages minimales :
  - accueil,
  - recherche,
  - liste des artistes,
  - fiche détail artiste,
  - page morceaux/releases,
  - page graphe,
  - page statistiques.
- Implémenter l’interface de recherche et l’import d’artiste.
- Afficher les morceaux, albums, collaborations et artistes liés.
- Ajouter une visualisation graphique simple du réseau d’artistes / morceaux.
- Mettre en valeur les statistiques (top artistes, top collaborations, top genres).

## 6. Docker, données et documentation
- Créer `docker-compose.yml` pour :
  - backend,
  - frontend,
  - Neo4j.
- Créer `.env.example` avec les variables attendues.
- Organiser le repo :
  - `backend/`,
  - `frontend/`,
  - `data/`,
  - `docs/`.
- Documenter :
  - modèle de données,
  - architecture,
  - choix techniques,
  - mode d’utilisation.
- Fournir un jeu de données ou un exemple d’import à partir de MusicBrainz.
- Préparer un README final clair et professionnel.

## Résultat attendu
- Phase 1 : analyse et design validés.
- Phase 2 : backend fonctionnel avec import MusicBrainz + Neo4j.
- Phase 3 : collaborations détectées et relations créées.
- Phase 4 : API publique exposée.
- Phase 5 : frontend connecté et visualisation opérationnelle.
- Phase 6 : tout dockerisé et documenté.
