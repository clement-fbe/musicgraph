# MusicGraph TP — Contexte et découpage

## Sources
- `README.md` : cahier des charges du projet MusicGraph.
- `Introduction au NoSQL .pdf` : introduction aux bases de données NoSQL, aux modèles de données et aux bases graphiques.

## Objectif principal
Construire une application web capable de :
- rechercher des artistes via l'API MusicBrainz,
- importer et stocker des artistes dans Neo4j,
- récupérer les morceaux et releases associés,
- détecter les collaborations et les featuring,
- visualiser les relations sous forme de graphe,
- exposer une API backend et une interface frontend,
- documenter le projet et le dockeriser.

## Fonctions attendues
- recherche d'artistes MusicBrainz par nom
- import d'un artiste dans Neo4j avec création / mise à jour d'un nœud `Artist`
- évitement des doublons via le MBID
- stockage des enregistrements (`Recording` ou `Track`)
- stockage des albums / releases
- détection des collaborations et relations entre artistes
- visualisation des artistes, morceaux, albums et graphes
- pages web : accueil, recherche, liste d'artistes, détail artiste, graphe, statistiques
- API REST exposant les principales ressources et statistiques

## Modèle de données Neo4j attendu
### Nœuds
- `Artist`
- `Recording` / `Track`
- `Release` / `Album`
- `Label`
- `Genre`
- `Area`

### Relations
- `(:Artist)-[:PERFORMED]->(:Recording)`
- `(:Artist)-[:FEATURED_ON]->(:Recording)`
- `(:Artist)-[:COLLABORATED_WITH]->(:Artist)`
- `(:Recording)-[:APPEARS_ON]->(:Release)`
- `(:Release)-[:RELEASED_BY]->(:Label)`
- `(:Artist)-[:ASSOCIATED_WITH_GENRE]->(:Genre)`
- `(:Artist)-[:FROM_AREA]->(:Area)`
- `(:Release)-[:RELEASED_IN]->(:Area)`

### Qualité des données
- utiliser les MBID pour éviter les doublons
- normaliser les données
- gérer les erreurs API
- limiter les appels MusicBrainz
- traiter les données manquantes

## NoSQL et graphes
- NoSQL = alternative à SQL pour la flexibilité, la scalabilité, la vitesse et la variété des données.
- Les bases graphes modélisent les données par nœuds, relations et propriétés.
- Neo4j utilise Cypher pour créer, rechercher et manipuler des graphes.

## Découpage du TP en parties
1. **Partie 1 — Contexte et design**
   - comprendre le besoin et les contraintes
   - choisir la modélisation graphes
   - définir les entités et relations
2. **Partie 2 — Backend et import**
   - implémenter l'API de recherche MusicBrainz
   - importer les artistes et leurs enregistrements dans Neo4j
   - gérer les doublons et la mise à jour des nœuds
3. **Partie 3 — Relations et analyse**
   - détecter les collaborations et featuring
   - relier artistes, enregistrements et releases
   - calculer des statistiques et top connexions
4. **Partie 4 — Frontend**
   - construire l'interface utilisateur
   - afficher les artistes, les détails et le graphe
   - proposer des statistiques et une exploration visuelle
5. **Partie 5 — Docker, données et documentation**
   - créer `docker-compose.yml` et `.env.example`
   - structurer le repo avec backend, frontend, data, docs
   - documenter le projet et fournir un jeu de données

## Contraintes clés
- backend API obligatoire
- frontend présent
- base Neo4j utilisée
- utilisation de MusicBrainz
- Docker + Docker Compose
- `.env.example`
- README complet et professionnel
- documentation du modèle et des choix techniques
