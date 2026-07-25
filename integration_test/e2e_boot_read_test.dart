// E2E: app boots and a surah opens with Arabic + translation actually rendered.
// Fails on any platform where init/DB/translation loading is broken.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran/controllers/quran_controller.dart';
import 'package:quran/controllers/translation_controller.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots, opens Surah 1, renders Arabic + translation',
      (tester) async {
    await bootApp(tester);

    // Surah list loaded
    final quran = Get.find<QuranController>();
    expect(quran.surahs.length, greaterThan(0),
        reason: 'surah list should load from storage');

    // Open Al-Fatiha
    await openSurah(tester, 1);

    // The selected translation for 1:1 must be available AND on screen.
    final tc = Get.find<TranslationController>();
    final verse = tc.verseText(1, 1);
    expect(verse, isNotEmpty,
        reason: 'selected translation for 1:1 should be loaded');

    final probe = verse.length > 15 ? verse.substring(0, 15) : verse;
    await pumpUntilFound(tester, find.textContaining(probe),
        timeout: const Duration(seconds: 10),
        reason: 'translation text rendered under the ayah');

    // At least Surah 1's ayahs are on screen (ayah cards carry ayah_<n>_ keys).
    final ayahCards = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('ayah_'));
    expect(ayahCards, findsWidgets, reason: 'ayah cards should render');
  });
}
