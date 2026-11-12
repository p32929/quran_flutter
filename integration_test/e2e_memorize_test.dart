// E2E: the Memorize screen downloads a surah's recitation to the device and
// loops it from the downloaded files. Uses the real download (network ->
// app documents folder) and real playback, so it fails wherever file storage
// or local-file audio is broken.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran/controllers/audio_controller.dart';
import 'package:quran/controllers/memorize_controller.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('download Surah 1 for memorizing and loop it', (tester) async {
    await bootApp(tester);
    await openSurah(tester, 1);

    await tester.tap(find.byTooltip('Memorize'));
    await pumpUntilFound(tester, find.text('Download 7 ayahs'),
        timeout: const Duration(seconds: 30),
        reason: 'the download button on the Memorize screen');

    final mem = Get.find<MemorizeController>();
    await tester.tap(find.text('Download 7 ayahs'));
    final downloaded = await pumpUntilTrue(
        tester, () => mem.isDownloaded.value && !mem.isDownloading.value,
        timeout: const Duration(seconds: 90));
    expect(downloaded, isTrue,
        reason: 'all 7 ayahs should be saved on the device');

    await tester.tap(find.byIcon(Icons.repeat).first);
    final audio = Get.find<AudioController>();
    final played = await pumpUntilTrue(
      tester,
      () => audio.isPlaying.value && audio.audioPlayer.position > Duration.zero,
      timeout: const Duration(seconds: 45),
    );
    expect(played, isTrue,
        reason: 'the downloaded files should play in a loop');

    await mem.stopLoop();
    await mem.deleteDownload();
    expect(mem.isDownloaded.value, isFalse);
  });
}
