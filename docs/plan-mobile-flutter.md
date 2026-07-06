# 📱 Plan — App mobile Flutter MusicGraph (version évaluation)

> ⏰ **DEADLINE : 7 juillet 23h59** (dernier cours). Plan volontairement **minimal**, centré sur la grille d'évaluation. En **binôme** (autorisé).

---

## 🎯 Contexte & stratégie

- **Sujet imposé** : un **catalogue** récupéré via une **API (JSON)**, avec liste responsive, page détail, et une fonctionnalité native.
- **Thématique choisie** : **MusicGraph** (catalogue d'**artistes** au lieu de « lieux/événements »).
  - ⚠️ **À valider avec le prof** (la slide dit « venez me proposer vos idées » pour un changement de thématique).
- **Backend réutilisé** : l'API REST **FastAPI** existante (MusicBrainz + Spotify pour les pochettes) fournit déjà des données JSON avec images. **On ne refait pas le backend**, l'app Flutter le consomme.
- **free-apis.github.io** : c'est juste un **annuaire** d'APIs gratuites, **pas une API imposée**. MusicBrainz/Spotify suffisent → on ne l'utilise pas.

---

## ✅ Grille d'évaluation (ce qui est noté)

| # | Critère | Exigence exacte | Mise en œuvre MusicGraph |
|---|---|---|---|
| 1 | **Catalogue (API & UI)** | Liste récupérée via API JSON. Data : Titre, Image, Description, (GPS), Date | Liste d'artistes via `GET /artists` : nom, cover, pays/type, dates |
| 2 | **Responsivité** | **Mobile → ListView** (liste verticale) · **Tablette → GridView** (grille) | `LayoutBuilder`/`MediaQuery`, breakpoint ~600 dp |
| 3 | **Détail & Navigation** | Tap sur une carte → page détail : description complète + **image en grand** | Écran détail artiste |
| 4 | **Fonctionnalité Native (« Le Plus »)** | Bouton natif — Caméra **ou** GPS | **Caméra : scan d'un QR code Spotify** → ouvre l'artiste (`mobile_scanner`) |

> **Note GPS** : le champ GPS et la vérif de distance étaient pensés pour des *lieux*. Avec la thématique artistes, on remplace le « Plus » par le **scan caméra** (native, valide le critère).

---

## 📷 Fonctionnalité native retenue

- **Caméra → scan d'un QR code** contenant un lien/URI Spotify (`https://open.spotify.com/artist/...` ou `spotify:artist:...`) ou un nom d'artiste.
- Package : **`mobile_scanner`**.
- Flux : scan → parse le contenu (extraction ID/nom) → `GET /search/artists?q=` → navigation vers le **détail** de l'artiste.
- ⚠️ Limite : on scanne des **QR codes**, pas les vrais « Spotify Codes » à pastilles (non décodables par une app tierce). Pour la démo, générer des QR codes contenant un lien/nom Spotify.

---

## 🏗️ Architecture (légère mais propre)

Feature-First + MVVM + Riverpod (pratiques vues en cours) :

```
lib/
├── main.dart              # ProviderScope
├── core/
│   ├── api/               # ApiClient (http)
│   ├── theme/             # thème Material 3
│   └── router/            # go_router
└── features/
    ├── catalogue/         # data / domain / presentation  (liste responsive)
    ├── detail/            # page détail
    └── scan/              # scan QR caméra
```

Règle SoC : le ViewModel (Notifier Riverpod) **n'importe aucun widget**.

---

## 🎯 MVP (obligatoire) vs Bonus (si le temps le permet)

**MVP — à finir en priorité pour valider :**
1. Catalogue responsive (ListView/GridView) via API
2. Page détail + navigation
3. Scan QR caméra → artiste

**Bonus (rapides) :** launcher icon personnalisé · favoris en `SharedPreferences` · recherche/import d'artistes.
**À ne PAS faire** (hors grille, chronophage) : graphe, stats, biométrie.

---

# 👥 Répartition à 2 personnes

Découpage **par partie = 1 branche = 1 prompt**. Les commandes Git encadrent chaque tâche.

> ⚠️ **Sync de départ (~15 min ensemble)** : valider les **contrats partagés** — le modèle `Artist` (`fromJson`) et l'interface `ApiClient`. **Personne A** les crée et push en premier, **Personne B** part de là.

## 🌿 Mise en place initiale du dépôt (une fois, Personne A)

```bash
git init
git add .
git commit -m "chore: init repo MusicGraph"
git remote add origin <URL_DU_REPO>
git branch -M main
git push -u origin main
git checkout -b develop
git push -u origin develop
```

Personne B :

```bash
git clone <URL_DU_REPO>
cd <dossier-du-projet>
git checkout develop
```

**Branches :** `main` (stable) ← `develop` (intégration) ← `feature/aX-...` / `feature/bX-...`.

---

## 👤 Personne A — Setup, API & Catalogue responsive

### A1 — Setup projet (lead) · branche `feature/a1-setup`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/a1-setup
```

> Crée un projet Flutter `musicgraph_mobile` dans `mobile/`. Ajoute les dépendances : `flutter_riverpod`, `http`, `go_router`, `mobile_scanner`, `cached_network_image`, et (bonus) `shared_preferences`, `flutter_launcher_icons`. Mets en place l'arborescence Feature-First : `lib/core/{api,theme,router}` et `lib/features/{catalogue,detail,scan}/{data,domain,presentation}`. Ajoute un `.gitignore` Flutter (`/build/`, `.dart_tool/`…). Configure `ProviderScope` dans `main()`. Vérifie `flutter run`.

```bash
git add . && git commit -m "chore(mobile): init Flutter + structure + deps"
git push -u origin feature/a1-setup
# → PR feature/a1-setup → develop
```

### A2 — ApiClient + modèle Artist (partagés) · branche `feature/a2-api-model`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/a2-api-model
```

> Dans `lib/core/api/`, crée un `ApiClient` (`http`) avec base URL configurable (émulateur Android `http://10.0.2.2:8000/api`, iOS `http://localhost:8000/api`, device réel IP LAN), méthodes `get(path)`/`post(path,body)`, gestion d'erreurs (timeout, status != 2xx → exception typée). Dans `features/catalogue/domain/`, crée le modèle immuable `Artist` (mbid, name, imageUrl, description, date) avec `fromJson`/`toJson` et valeurs par défaut sûres. **Contrats partagés — push en priorité pour débloquer Personne B.**

```bash
git add . && git commit -m "feat(core): ApiClient + modèle Artist"
git push -u origin feature/a2-api-model
# → PR prioritaire → develop
```

### A3 — Catalogue responsive (ListView / GridView) · branche `feature/a3-catalogue`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/a3-catalogue
```

> Implémente le **catalogue** en MVVM (critère #1 + #2). Repository appelant `GET /artists`, ViewModel Riverpod exposant `AsyncValue<List<Artist>>` (loading/error/data). UI **responsive** : `LayoutBuilder`/`MediaQuery` avec breakpoint ~600 dp → **ListView** (liste verticale) sur mobile, **GridView** (grille) sur tablette. Chaque carte affiche image (`cached_network_image`), titre, courte description ; tap → navigation vers le détail (route de B1). Gère état vide + erreur + pull-to-refresh.

```bash
git add . && git commit -m "feat(catalogue): liste responsive ListView/GridView via API"
git push -u origin feature/a3-catalogue
# → PR feature/a3-catalogue → develop
```

### A4 — Bonus : favoris + launcher icon · branche `feature/a4-bonus`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/a4-bonus
```

> (Si le temps le permet) 1) Favoris : `shared_preferences` intégré à Riverpod (provider init async + `overrideWithValue`), stockage de la liste des favoris en JSON (`jsonEncode`/`jsonDecode`), lecture protégée par `try/catch` → liste vide si corrompu. Bouton favori sur les cartes/détail. 2) Launcher icon : asset `assets/icon/musicgraph.png`, config `flutter_launcher_icons` (Android/iOS, `min_sdk_android: 21`, `remove_alpha_ios: true`), puis `dart run flutter_launcher_icons`.

```bash
git add . && git commit -m "feat(bonus): favoris SharedPreferences + launcher icon"
git push -u origin feature/a4-bonus
# → PR feature/a4-bonus → develop
```

---

## 👤 Personne B — Navigation, Détail & Scan caméra

### B1 — Navigation, thème & accueil · branche `feature/b1-navigation`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/b1-navigation
```

> Mets en place `go_router` dans `lib/core/router/` : accueil, catalogue, détail (`/artist/:mbid`), scan. Crée un thème Material 3 (clair/sombre) dans `lib/core/theme/` et un écran d'accueil simple (accès catalogue + bouton scan). **Expose les noms de routes** pour que Personne A navigue vers le détail depuis les cartes.

```bash
git add . && git commit -m "feat(core): go_router + thème + accueil"
git push -u origin feature/b1-navigation
# → PR feature/b1-navigation → develop (débloque A3)
```

### B2 — Page détail · branche `feature/b2-detail`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/b2-detail
```

> Implémente la **page détail** (critère #3) en MVVM. Repository appelant `GET /artists/{mbid}`, ViewModel Riverpod (`AsyncValue`). UI : **image en grand** (`cached_network_image`), **description complète**, infos (pays, type, dates) et liste des recordings/collaborateurs si dispo. Utilise le modèle `Artist` de A2. Gère loading/erreur.

```bash
git add . && git commit -m "feat(detail): page détail artiste (image grand format + description)"
git push -u origin feature/b2-detail
# → PR feature/b2-detail → develop
```

### B3 — Fonctionnalité native : scan QR caméra · branche `feature/b3-scan`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/b3-scan
```

> Implémente le **« Plus »** (critère #4) avec `mobile_scanner`. Configure les permissions caméra (`Info.plist` `NSCameraUsageDescription` + `AndroidManifest.xml` `CAMERA`). Écran de scan : ouvre la caméra, détecte un **QR code** contenant un lien/URI Spotify (`open.spotify.com/artist/...`, `spotify:artist:...`) ou un nom d'artiste. Parse le contenu → extrait ID/nom → `GET /search/artists?q=` → navigation vers le **détail** de l'artiste trouvé. Gère : permission refusée, aucun résultat, erreur réseau.

```bash
git add . && git commit -m "feat(scan): scan QR caméra Spotify → détail artiste"
git push -u origin feature/b3-scan
# → PR feature/b3-scan → develop
```

### B4 — Bonus : doc, tests & rendu · branche `feature/b4-docs`

```bash
git checkout develop && git pull origin develop
git checkout -b feature/b4-docs
```

> Rédige `mobile/README.md` : lancement (`flutter run`), config de l'URL API selon la cible, tableau des choix d'archi (Feature-First, MVVM, Riverpod) et mapping avec la grille d'éval. Déroule le workflow de test : catalogue (mobile ListView / tablette GridView) → détail → scan QR. Ajoute quelques screenshots. Vérifie la checklist finale.

```bash
git add . && git commit -m "docs(mobile): README + tests + mapping grille éval"
git push -u origin feature/b4-docs
# → PR feature/b4-docs → develop
```

---

## 🔗 Dépendances & ordre conseillé

| Bloquant | Produit par | Consommé par |
|---|---|---|
| `ApiClient` + modèle `Artist` (A2) | A | B2, B3 |
| Routes / navigation (B1) | B | A3 (cartes → détail) |

**Ordre :** A1 → A2 et B1 (fondations) en premier, puis en parallèle A3 (catalogue) / B2 (détail) / B3 (scan), enfin les bonus (A4, B4).

---

# 🔁 Règles Git communes

### Fusionner une tâche (via Pull Request)
1. `git push` la branche.
2. Ouvrir une **PR** `feature/...` → `develop`.
3. L'autre relit et merge.

Alternative CLI :
```bash
git checkout develop && git pull origin develop
git merge feature/a3-catalogue
git push origin develop
```

### Rester synchro (≥ 1x/jour, ici plutôt souvent vu la deadline)
```bash
git checkout feature/a3-catalogue
git merge origin/develop
```

### Résoudre un conflit
```bash
git merge origin/develop
# éditer les fichiers en conflit, supprimer <<<<<<< ======= >>>>>>>
git add <fichier-résolu>
git commit
git push
```

### Livraison finale
```bash
git checkout main && git pull origin main
git merge develop
git tag -a v1.0 -m "Rendu MusicGraph mobile"
git push origin main --tags
```

### Bonnes pratiques
- **1 partie = 1 branche = 1 PR**, petites PR.
- **Jamais de push direct sur `main`.**
- Commits Conventional Commits : `feat:`, `fix:`, `chore:`, `docs:`.
- Partager tôt les contrats (A2) pour débloquer l'autre.

---

## 🔌 Endpoints API utiles

Base : `http://<host>:8000/api/`
- `GET /artists` — liste (catalogue)
- `GET /artists/{mbid}` — détail
- `GET /search/artists?q=` — recherche (utilisé par le scan)
- `GET /health` — santé backend

## ⚠️ Points d'attention
1. **Réseau** : backend Docker sur `localhost` → depuis émulateur/device utiliser l'IP adaptée. Device sur le même réseau que la machine.
2. **CORS** : autoriser le client mobile côté FastAPI.
3. **Permissions caméra** : à déclarer (iOS `NSCameraUsageDescription`, Android `CAMERA`).
4. **Thématique** : faire valider le sujet MusicGraph par le prof avant de foncer.

## ✅ Checklist finale (grille)
- [ ] Catalogue via API JSON (titre, image, description, date)
- [ ] Responsivité : ListView (mobile) / GridView (tablette)
- [ ] Détail + navigation (image en grand + description complète)
- [ ] Fonctionnalité native : scan QR caméra → artiste
- [ ] (Bonus) launcher icon · favoris · recherche
