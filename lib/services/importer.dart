import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'quran_repository.dart';

class DataImporter {
  final QuranRepository repo;

  DataImporter(this.repo);

  // Reads assets/data/surahs.json and all available assets/data/surah_{n}.json
  // Populates Sembast stores: surah_index and surah_detail
  Future<void> importAll({void Function(int done, int total)? onProgress}) async {
    // 1) Import surah index (surahs.json)
    final String indexStr = await rootBundle.loadString('assets/data/surahs.json');
    final List<dynamic> rawList = json.decode(indexStr);

    // Assign sequential number if not present and normalize keys to match Surah.fromJson
    final normalized = <Map<String, dynamic>>[];
    for (int i = 0; i < rawList.length; i++) {
      final m = Map<String, dynamic>.from(rawList[i] as Map);
      // Ensure number is present (1-indexed)
      m['number'] = m['number'] ?? (i + 1);
      // Ensure keys that Surah.fromJson expects exist
      m['surahName'] = m['surahName'] ?? m['name'] ?? '';
      m['surahNameArabic'] = m['surahNameArabic'] ?? m['nameArabic'] ?? '';
      m['surahNameArabicLong'] = m['surahNameArabicLong'] ?? m['nameArabicLong'] ?? '';
      m['surahNameTranslation'] = m['surahNameTranslation'] ?? m['nameTranslation'] ?? '';
      m['revelationPlace'] = m['revelationPlace'] ?? m['revelation'] ?? '';
      m['totalAyah'] = m['totalAyah'] ?? m['ayahCount'] ?? 0;
      normalized.add(m);
    }
    await repo.putSurahIndexBatch(normalized);

    // 2) Import available per-surah details lazily
    // We will attempt 1..114 and ignore missing assets (some repos may not include all).
    const int total = 114;
    int done = 0;

    for (int n = 1; n <= total; n++) {
      try {
        final path = 'assets/data/surah_$n.json';
        final String s = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonMap = json.decode(s);

        // Ensure surahNo is present and equals n
        jsonMap['surahNo'] = jsonMap['surahNo'] ?? n;

        await repo.putSurahDetail(n, jsonMap);
      } catch (_) {
        // Missing file is fine; will be loaded lazily on demand
      } finally {
        done++;
        onProgress?.call(done, total);
      }
    }
  }
}
