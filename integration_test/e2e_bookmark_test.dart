// E2E: bookmarking an ayah updates state and persists to storage.
// Fails on any platform where bookmark toggling or persistence is broken.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pref/pref.dart';
import 'package:quran/controllers/bookmark_controller.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bookmarking ayah 1 adds it and persists', (tester) async {
    await bootApp(tester);
    await openSurah(tester, 1);

    final bm = Get.find<BookmarkController>();
    final before = bm.bookmarks.length;

    await tester.tap(find.byTooltip('Bookmark').first);
    await pumpUntilTrue(tester, () => bm.isBookmarked(1, 1),
        timeout: const Duration(seconds: 5));

    expect(bm.isBookmarked(1, 1), isTrue,
        reason: 'ayah 1:1 should be bookmarked after tapping');
    expect(bm.bookmarks.length, greaterThan(before));

    // Persisted to the platform pref store.
    final pref = Get.find<BasePrefService>();
    expect(pref.get<String>(BookmarkController.BOOKMARKS_KEY), isNotNull,
        reason: 'bookmarks should be written to storage');

    // Clean up so re-runs start fresh.
    await tester.tap(find.byTooltip('Bookmark').first);
    await pumpUntilTrue(tester, () => !bm.isBookmarked(1, 1),
        timeout: const Duration(seconds: 5));
  });
}
