import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance unique de [SharedPreferences] chargée au démarrage.
///
/// Elle est **surchargée dans `main()`** via `overrideWithValue` après un
/// `await SharedPreferences.getInstance()` (lecture asynchrone unique du
/// fichier natif — cf. cours SharedPreferences & Riverpod).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé dans main().',
  );
});
