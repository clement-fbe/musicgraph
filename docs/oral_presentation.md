# Script oral duo - MusicGraph

## Repartition

- Intervenant 1 : contexte, architecture, backend, demonstration.
- Intervenant 2 : modele graphe, interface, resultats, bilan, conclusion.

Objectif de duree : environ 6 a 8 minutes.

---

## Slide 1 - Introduction

**Intervenant 1**

Bonjour, aujourd'hui nous allons vous presenter notre projet NoSQL : **MusicGraph**.

L'idee du projet est de partir de donnees musicales brutes, recuperees via MusicBrainz, pour les transformer en un graphe exploitable. On ne veut pas seulement afficher des artistes ou des albums dans une liste : on veut pouvoir explorer les relations entre eux.

MusicGraph repose sur une stack complete : **FastAPI** pour le backend, **React** pour l'interface, **Neo4j** pour la base graphe, et **Docker** pour rendre le projet facile a lancer.

**Intervenant 2**

Le but final est donc d'avoir une application web qui permet de chercher un artiste, de l'importer, d'enrichir ses donnees musicales, puis de visualiser les liens sous forme de graphe.

---

## Slide 2 - Pourquoi ce projet

**Intervenant 1**

On a choisi ce sujet parce que la musique forme naturellement un reseau.

Un artiste est lie a des morceaux, des albums, mais aussi indirectement a d'autres artistes. Par exemple, deux artistes peuvent etre relies parce qu'ils apparaissent sur un meme enregistrement, une meme sortie, ou une collaboration.

**Intervenant 2**

Dans une base relationnelle classique, ces liens peuvent vite devenir difficiles a explorer, car il faut multiplier les jointures.

Avec une base graphe comme Neo4j, le modele est plus naturel : les entites deviennent des noeuds, et les connexions deviennent des relations. C'est exactement ce que l'on cherche a rendre lisible dans MusicGraph.

---

## Slide 3 - Vue d'ensemble

**Intervenant 1**

Le projet n'est pas seulement une API. On a construit une chaine complete.

D'abord, l'utilisateur interagit avec le frontend React : il peut rechercher un artiste, consulter ses details et afficher un graphe interactif.

Ensuite, le backend FastAPI centralise la logique metier. Il sert d'intermediaire entre l'interface, MusicBrainz et Neo4j.

**Intervenant 2**

Neo4j stocke les noeuds et les relations musicales, et Docker permet de lancer les services de facon reproductible.

Cette organisation nous permet de separer clairement les responsabilites : React pour l'experience utilisateur, FastAPI pour les traitements, Neo4j pour l'exploration des relations, et Docker pour l'environnement.

---

## Slide 4 - Backend

**Intervenant 1**

Le backend a un role important, parce qu'il rend les donnees MusicBrainz plus simples a utiliser.

On a notamment un endpoint `GET /api/search/artists`, qui interroge MusicBrainz pour rechercher des artistes. Pour respecter l'API, on utilise un User-Agent dedie.

On a aussi `POST /api/import/artists`, qui cree ou met a jour un noeud `Artist` dans Neo4j.

**Intervenant 2**

Et enfin, `POST /api/enrich/artists` sert a enrichir les donnees. Il ajoute les recordings, prepare les relations et permet ensuite de construire les collaborations.

Un point important du backend, c'est la robustesse : on a ajoute des retries, un backoff, et un fallback mock. Comme MusicBrainz depend du reseau, cela evite que toute la demonstration echoue si l'API externe repond mal.

---

## Slide 5 - Modele graphe

**Intervenant 2**

Le coeur du projet, c'est le modele graphe.

Dans Neo4j, on stocke principalement des noeuds comme `Artist`, `Recording` et `Release`. Chaque artiste possede un identifiant stable, le **MBID**, qui vient de MusicBrainz.

Les relations permettent ensuite de representer ce que l'on veut explorer. Par exemple, un artiste peut avoir une relation `PERFORMED` vers un enregistrement, un enregistrement peut apparaitre sur une sortie avec `APPEARS_ON`, et deux artistes peuvent etre lies par `COLLABORATED_WITH`.

**Intervenant 1**

L'avantage, c'est que le graphe correspond directement a la question du projet : qui est lie a quoi, et comment ?

Au lieu de reconstruire les liens a chaque requete, Neo4j nous permet de les stocker et de les parcourir plus naturellement.

---

## Slide 6 - Interface

**Intervenant 2**

Cote frontend, l'objectif etait de transformer les endpoints en vrai parcours utilisateur.

L'application contient plusieurs pages : une page d'accueil pour comprendre le projet, une page de recherche pour trouver et importer un artiste, une page de liste pour voir les artistes stockes, une page detail pour consulter les recordings et collaborateurs, une page graphe pour l'exploration visuelle, et une page statistiques.

**Intervenant 1**

Les appels API sont centralises avec Axios. Cela permet de garder les composants React plus lisibles, et d'eviter de dupliquer la logique d'appel au backend dans chaque page.

L'interface sert donc de couche d'exploration : elle rend les donnees accessibles, pas seulement stockees.

---

## Slide 7 - Demo

**Intervenant 1**

Pour la demonstration, on suit le trajet reel d'une donnee.

Premiere etape : on lance l'environnement avec `docker compose up -d --build`. Cela demarre les services necessaires, notamment le backend, le frontend et Neo4j.

Deuxieme etape : on recherche un artiste, par exemple **Daft Punk**, depuis la page Search.

**Intervenant 2**

Troisieme etape : on importe l'artiste. Il est alors persiste dans Neo4j avec son identifiant MusicBrainz.

Quatrieme etape : on consulte les details, puis on affiche le graphe avec Cytoscape. L'objectif de cette demo est de montrer que le projet fonctionne de bout en bout : recherche, import, persistance, enrichissement et visualisation.

---

## Slide 8 - Resultats

**Intervenant 2**

Au niveau des resultats, on obtient une base solide pour une application full-stack.

Le projet contient plusieurs pages React, plusieurs endpoints backend, trois services Docker, et un modele graphe central dans Neo4j.

**Intervenant 1**

Les points valides sont importants : le health check fonctionne, l'import est operationnel, la persistance Neo4j a ete verifiee, la navigation frontend est fonctionnelle, et le build de production React a ete valide.

Le fallback mock est aussi un vrai point fort, parce qu'il securise la demo et permet de continuer a tester meme si MusicBrainz n'est pas disponible.

---

## Slide 9 - Bilan

**Intervenant 1**

Le projet fonctionne, mais il reste des limites et des ameliorations possibles.

La premiere priorite serait d'aller plus loin sur les collaborations, en important aussi les artistes credites sur les recordings, pas seulement les donnees de base.

**Intervenant 2**

Il faudrait aussi brancher les cartes de statistiques sur de vraies donnees, et mieux utiliser la configuration frontend, par exemple avec `VITE_API_BASE` au lieu d'une URL codee en dur.

Pour la suite, on pourrait ajouter des index Neo4j, des tests automatises, des filtres sur le graphe, et exploiter plus finement les donnees MusicBrainz.

---

## Slide 10 - Conclusion

**Intervenant 2**

Pour conclure, MusicGraph relie plusieurs briques : une API musicale, un backend robuste, une base graphe et une interface de visualisation.

Neo4j est adapte au probleme, parce que le sujet principal est l'exploration de relations.

**Intervenant 1**

Docker rend le projet reproductible, FastAPI structure la logique metier, et React rend les donnees explorables par l'utilisateur.

Notre projet montre donc comment passer de donnees musicales brutes a un graphe consultable, interactif et extensible.

Merci pour votre attention. Nous sommes maintenant disponibles pour vos questions.

---

## Questions possibles

### Pourquoi Neo4j plutot qu'une base SQL ?

Parce que le coeur du projet est l'exploration de relations. Neo4j permet de representer directement les artistes, morceaux, albums et collaborations sous forme de noeuds et de relations.

### Pourquoi utiliser MusicBrainz ?

MusicBrainz fournit des identifiants stables, comme les MBID, et des donnees ouvertes sur les artistes, recordings et releases.

### A quoi sert le fallback mock ?

Il permet de garder l'application utilisable si MusicBrainz est lent ou indisponible. C'est surtout utile pour les tests et les demonstrations.

### Quelle serait la prochaine amelioration prioritaire ?

La priorite serait d'enrichir les collaborations avec davantage d'artistes credites, puis d'ajouter des filtres et des tests automatises.