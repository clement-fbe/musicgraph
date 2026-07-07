import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une URL (lien Spotify) dans l'app/navigateur externe.
Future<void> openExternal(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  final ok = uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
    );
  }
}

/// Ouvre la feuille de partage native avec un texte (nom + lien Spotify).
Future<void> shareText(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}
