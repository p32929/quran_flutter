// Feature #1 — Local database (QuranRepository).
// Platform-specific: uses sembast_web (IndexedDB) on web and sembast_io +
// path_provider (a file on disk) on native. This test exercises the real
// platform storage on whichever platform it runs on. Runs on ALL platforms.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran/services/quran_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QuranRepository platform storage round-trip', () {
    late QuranRepository repo;

    setUpAll(() async {
      repo = QuranRepository();
      await repo.open();
    });

    tearDownAll(() async {
      await repo.close();
    });

    testWidgets('surah index + detail persist and read back', (tester) async {
      await repo.putSurahIndexBatch([
        {'number': 999, 'name': 'IntegrationTest', 'totalAyah': 3},
      ]);
      final all = await repo.getAllSurahIndex();
      expect(all.any((m) => m['number'] == 999), isTrue,
          reason: 'surah index record should be readable after write');

      await repo.putSurahDetail(999, {
        'surahNo': 999,
        'arabic1': ['a', 'b', 'c'],
      });
      final detail = await repo.getSurahDetail(999);
      expect(detail, isNotNull);
      expect(detail!['surahNo'], 999);
      expect((detail['arabic1'] as List).length, 3);
    });

    testWidgets('downloaded translation edition persists, lists, deletes',
        (tester) async {
      const id = 'integration-test-edition';
      await repo.putTranslationEdition(id, {
        '1': ['verse-1-1', 'verse-1-2'],
        '2': ['verse-2-1'],
      });

      final stored = await repo.getTranslationEdition(id);
      expect(stored, isNotNull);
      expect((stored!['1'] as List).length, 2);

      final ids = await repo.getDownloadedEditionIds();
      expect(ids, contains(id));

      await repo.deleteTranslationEdition(id);
      expect(await repo.getTranslationEdition(id), isNull,
          reason: 'edition should be gone after delete');
    });

    testWidgets('data version persists', (tester) async {
      await repo.setDataVersion(4242);
      expect(await repo.getDataVersion(), 4242);
    });
  });
}
