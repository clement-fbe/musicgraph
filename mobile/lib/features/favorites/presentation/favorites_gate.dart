import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'favorites_screen.dart';

/// Protège l'accès aux favoris par authentification biométrique (local_auth).
/// Si l'appareil n'a aucune sécurité configurée, on laisse passer (pas de blocage).
class FavoritesGate extends StatefulWidget {
  const FavoritesGate({super.key});

  @override
  State<FavoritesGate> createState() => _FavoritesGateState();
}

class _FavoritesGateState extends State<FavoritesGate> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _authenticated = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _checking = true);
    var ok = false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        ok = true; // aucun verrou dispo -> on n'enferme pas l'utilisateur
      } else {
        ok = await _auth.authenticate(
          localizedReason: 'Déverrouille l\'accès à tes favoris',
          biometricOnly: false,
          persistAcrossBackgrounding: true,
        );
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _authenticated = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return const FavoritesScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64),
                  const SizedBox(height: 12),
                  const Text('Favoris verrouillés'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Déverrouiller'),
                  ),
                ],
              ),
      ),
    );
  }
}
