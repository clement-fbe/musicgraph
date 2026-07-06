import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Exception typée remontée par [ApiClient] (couche Data).
/// La couche présentation peut afficher [message] et réagir selon [statusCode].
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException(${statusCode ?? '—'}): $message';
}

/// Client HTTP de bas niveau pour l'API MusicGraph.
///
/// Couche Data pure : aucune dépendance à Flutter/widgets.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// URL de base de l'API selon la cible d'exécution :
  /// - Émulateur Android         : `http://10.0.2.2:8000/api`
  /// - Simulateur iOS / desktop  : `http://localhost:8000/api`
  /// - TÉLÉPHONE RÉEL (USB/Wi-Fi): `http://<IP_LAN_DU_PC>:8000/api`
  ///   (ex: `http://192.168.1.20:8000/api` — le tel doit être sur le même réseau)
  static const String defaultBaseUrl = 'http://10.31.32.32:8000/api';

  final String baseUrl;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  /// GET `path` (ex: `/artists`). Retourne le JSON décodé (Map ou List).
  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final res = await _client.get(uri).timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      throw const ApiException('Délai d\'attente dépassé.');
    } on SocketException {
      throw const ApiException('Serveur injoignable (vérifie le réseau / l\'IP).');
    }
  }

  /// POST `path` avec un corps JSON optionnel.
  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      throw const ApiException('Délai d\'attente dépassé.');
    } on SocketException {
      throw const ApiException('Serveur injoignable (vérifie le réseau / l\'IP).');
    }
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(
      'Erreur serveur (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  void close() => _client.close();
}

/// Provider Riverpod exposant l'[ApiClient] partagé à toute l'app.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});
