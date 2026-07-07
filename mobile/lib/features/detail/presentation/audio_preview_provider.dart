import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Contrôleur d'extrait audio : un seul lecteur, un seul extrait à la fois.
/// `state` = l'URL de l'extrait en cours de lecture (ou null).
class AudioPreviewController extends Notifier<String?> {
  final AudioPlayer _player = AudioPlayer();

  @override
  String? build() {
    ref.onDispose(_player.dispose);
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _player.stop();
        state = null;
      }
    });
    return null;
  }

  Future<void> toggle(String url) async {
    if (state == url) {
      await _player.stop();
      state = null;
      return;
    }
    state = url;
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      state = null;
    }
  }
}

final audioPreviewProvider =
    NotifierProvider<AudioPreviewController, String?>(AudioPreviewController.new);
