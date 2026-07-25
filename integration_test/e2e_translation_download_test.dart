// E2E: download a translation on demand and have it render under the ayah.
// Drives the real pipeline the Download button calls: HTTP fetch -> Sembast
// store -> in-memory cache -> select -> UI rebuild. Fails on any platform where
// the network entitlement/permission or the web-vs-native storage path is broken.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran/controllers/translation_controller.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const editionId = 'fra-muhammadhamidul'; // French — a downloadable edition

  testWidgets('download a French translation and see it under the ayah',
      (tester) async {
    await bootApp(tester);
    await openSurah(tester, 1);

    final tc = Get.find<TranslationController>();

    // Real on-demand download (network -> Sembast -> cache).
    final ok = await tc.downloadEdition(editionId, selectWhenDone: true);
    expect(ok, isTrue,
        reason: 'download should succeed (network + storage available)');
    expect(tc.isDownloaded(editionId), isTrue);

    final verse = tc.verseText(1, 1);
    expect(verse, isNotEmpty,
        reason: 'downloaded French verse 1:1 should be stored and readable');

    // The details screen should now show the French text (UI reacted to select).
    final probe = verse.length > 15 ? verse.substring(0, 15) : verse;
    await pumpUntilFound(tester, find.textContaining(probe),
        timeout: const Duration(seconds: 10),
        reason: 'downloaded translation should render under the ayah');

    // Clean up: remove it and restore the default edition.
    await tc.deleteDownloaded(editionId);
    expect(tc.isDownloaded(editionId), isFalse);
  });
}
