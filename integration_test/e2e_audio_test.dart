// E2E: tapping an ayah's play button actually starts audio.
// Reads REAL playback state (isPlaying + the player position advancing past 0),
// so it fails on any platform where audio is wired but doesn't actually play.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran/controllers/audio_controller.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tapping play on ayah 1 actually plays audio',
    (tester) async {
      await bootApp(tester);
      await openSurah(tester, 1);

      await tester.tap(find.byTooltip('Play Ayah').first);

      final audio = Get.find<AudioController>();

      // Real playback = isPlaying flips true AND the position advances past 0.
      final played = await pumpUntilTrue(
        tester,
        () =>
            audio.isPlaying.value &&
            audio.audioPlayer.position > Duration.zero,
        timeout: const Duration(seconds: 45),
      );

      expect(played, isTrue,
          reason:
              'audio should actually start (isPlaying + position advancing)');
      expect(audio.currentAyahNumber.value, 1,
          reason: 'the playing ayah should be tracked as ayah 1');

      await audio.stopAudio();
    },
    // just_audio has no Windows/Linux backend — not a failure there.
    skip: !audioSupported,
  );
}
