// Feature #3 — Audio engine (just_audio) streaming a per-ayah URL.
// Platform-specific: different native backends (AVPlayer iOS/macOS, ExoPlayer
// Android, just_audio_web on web). NO desktop backend exists, so this is
// skipped on Windows/Linux. On native platforms it also proves the network
// entitlement/permission is in place (this is the old macOS -11800 path).
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

// just_audio supports these platforms only.
bool get _audioSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AudioPlayer loads a real per-ayah stream and reports a duration',
    (tester) async {
      final player = AudioPlayer();
      expect(player.playing, isFalse);

      // Al-Fatiha 1:1 from the app's real reciter source (a few seconds long).
      const url = 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3';
      final duration = await player.setUrl(url).timeout(
            const Duration(seconds: 45),
          );

      expect(duration, isNotNull,
          reason: 'platform audio backend + network should resolve a duration');
      expect(duration!.inMilliseconds, greaterThan(0));

      await player.dispose();
    },
    // just_audio has no Windows/Linux backend — skip there (not a failure).
    skip: !_audioSupported,
  );
}
