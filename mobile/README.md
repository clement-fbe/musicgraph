# MusicGraph Mobile

Application Flutter d'evaluation pour MusicGraph. Elle consomme l'API REST MusicGraph et expose un catalogue d'artistes, une page detail, des favoris locaux et un scan QR camera.

## Lancement

Pre-requis :

- Flutter installe et disponible dans le terminal.
- Backend MusicGraph accessible depuis la cible mobile.
- Dependencies installees avec `flutter pub get`.

Depuis ce dossier :

```bash
flutter pub get
flutter run
```

Commandes de verification :

```bash
flutter analyze
flutter test
```

## Configuration API

L'URL API est centralisee dans `lib/core/api/api_client.dart`, via `ApiClient.defaultBaseUrl`.

Valeur actuelle :

```dart
static const String defaultBaseUrl = 'https://musicgraph.alwaysdata.net/api';
```

Pour un backend local, adapter selon la cible :

| Cible | URL API |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` |
| iOS simulator / desktop | `http://localhost:8000/api` |
| Telephone reel | `http://<IP_LAN_DU_PC>:8000/api` |
| Backend deploye | `https://musicgraph.alwaysdata.net/api` |

Endpoints utilises :

| Usage | Endpoint |
|---|---|
| Catalogue | `GET /artists` |
| Detail artiste | `GET /artists/{mbid}` |
| Scan QR / recherche | `GET /search/artists?q=` |
| Sante backend | `GET /health` |

## Architecture

| Choix | Role dans l'app |
|---|---|
| Feature-First | Le code est regroupe par domaine fonctionnel : `catalogue`, `detail`, `scan`, `favorites`. |
| MVVM leger | Les widgets lisent des ViewModels Riverpod et ne contiennent pas les appels API directs. |
| Riverpod | Gestion des etats async : loading, error, data, refresh et favoris. |
| `go_router` | Navigation nommee : accueil, catalogue, detail artiste, scan, favoris. |
| `ApiClient` partage | Client HTTP centralise avec timeout, decodage JSON et erreurs typees. |
| `cached_network_image` | Chargement des images artistes avec placeholder et fallback. |
| `mobile_scanner` | Fonction native camera pour scanner un QR code. |
| `shared_preferences` | Bonus favoris persistes localement. |

Structure principale :

```text
lib/
  core/
    api/
    router/
    storage/
    theme/
  features/
    catalogue/
    detail/
    favorites/
    home/
    scan/
```

## Mapping grille d'evaluation

| Critere | Implementation MusicGraph |
|---|---|
| Catalogue via API JSON | `CatalogueScreen` consomme `GET /artists` via repository + provider Riverpod. |
| Titre, image, description, date | Les cartes affichent nom, image, description calculee et annee si disponible. |
| Responsive mobile/tablette | Breakpoint 600 dp : mobile en `ListView`, tablette en `GridView`. |
| Detail + navigation | Tap sur carte -> route `/artist/:mbid`, image grand format, description et infos detaillees. |
| Fonction native | Scan camera QR avec `mobile_scanner`. |
| Gestion erreurs | Etats loading/error/empty sur catalogue, detail et scan. |
| Bonus | Favoris persistants, launcher icon personnalisee. |

## Workflow de test manuel

1. Demarrer le backend ou verifier que l'API deployee repond.
2. Lancer l'app avec `flutter run`.
3. Depuis l'accueil, ouvrir le catalogue.
4. Sur mobile, verifier que les artistes sont affiches en liste verticale.
5. Sur tablette ou largeur >= 600 dp, verifier que les artistes sont affiches en grille.
6. Tirer vers le bas pour tester le refresh du catalogue.
7. Toucher une carte artiste.
8. Verifier la page detail : grande image, description, pays/type/date, recordings et collaborateurs si disponibles.
9. Revenir a l'accueil ou ouvrir l'action scan.
10. Scanner un QR code contenant l'une des valeurs suivantes :
    - `https://open.spotify.com/artist/<spotify_id>`
    - `spotify:artist:<spotify_id>`
    - un nom d'artiste, par exemple `Daft Punk`
11. Verifier que l'app recherche l'artiste puis navigue vers le detail.
12. Tester les erreurs attendues : permission camera refusee, QR vide/invalide, backend indisponible.
13. Ajouter/retirer un favori et verifier que l'etat reste apres redemarrage.

## QR codes de demo

Pour la demo, utiliser des QR codes standards. Les vrais Spotify Codes visuels ne sont pas decodables par une app tierce.

Exemples de contenu QR :

```text
Daft Punk
spotify:artist:4tZwfgrHOc3mvqYlEYSvVi
https://open.spotify.com/artist/4tZwfgrHOc3mvqYlEYSvVi
```

## Screenshots

Captures a ajouter au rendu si possible :

| Ecran | Fichier suggere |
|---|---|
| Accueil | `docs/screenshots/mobile-home.png` |
| Catalogue mobile ListView | `docs/screenshots/mobile-catalogue-list.png` |
| Catalogue tablette GridView | `docs/screenshots/mobile-catalogue-grid.png` |
| Detail artiste | `docs/screenshots/mobile-detail.png` |
| Scan QR | `docs/screenshots/mobile-scan.png` |

## Checklist finale

- [x] Catalogue via API JSON.
- [x] Liste responsive : `ListView` mobile, `GridView` tablette.
- [x] Navigation vers page detail.
- [x] Detail artiste avec image grand format et description.
- [x] Scan QR camera avec permission native.
- [x] Recherche via API depuis le scan.
- [x] Gestion loading/error/empty.
- [x] Bonus favoris locaux.
- [x] Bonus launcher icon.
- [ ] Captures d'ecran finales ajoutees au rendu.
