import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import 'quran_repository.dart';

class QuranService extends GetxService {
  // Repository (Sembast) injected or lazily found
  late final QuranRepository _repo;

  // In-memory caches
  final Map<int, SurahDetail> _cachedSurahDetails = {};
  List<Surah>? _cachedSurahs;

  // Fallback data if everything fails
  final List<Surah> _fallbackSurahs = [
    Surah(
      number: 1,
      name: 'Al-Faatiha',
      nameArabic: 'الفاتحة',
      nameArabicLong: 'سُورَةُ ٱلْفَاتِحَةِ',
      nameTranslation: 'The Opening',
      totalAyah: 7,
      revelationPlace: 'Mecca',
    ),
    Surah(
      number: 2,
      name: 'Al-Baqara',
      nameArabic: 'البقرة',
      nameArabicLong: 'সورة البقرة',
      nameTranslation: 'The Cow',
      totalAyah: 286,
      revelationPlace: 'Madina',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Find an existing repo (opened in bootstrap)
    if (Get.isRegistered<QuranRepository>()) {
      _repo = Get.find<QuranRepository>();
    } else {
      // As a fallback, create and open a repo (should already be opened by bootstrap)
      _repo = QuranRepository();
      _repo.open();
    }
    // Do not block here; let UI call getSurahs() which will be DB-first and fast.
  }

  // DB-first: memory -> DB -> assets (write-through)
  Future<List<Surah>> getSurahs() async {
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    // Try DB
    try {
      final listMaps = await _repo.getAllSurahIndex();
      if (listMaps.isNotEmpty) {
        _cachedSurahs = listMaps.map((m) => Surah.fromJson(m)).toList();
        return _cachedSurahs!;
      }
    } catch (e) {
      // proceed to assets fallback
      print('DB read for surah index failed, falling back to assets: $e');
    }

    // Fallback to assets (first run or DB unavailable)
    try {
      final String data = await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> surahsData = json.decode(data);

      _cachedSurahs = [];
      for (int i = 0; i < surahsData.length; i++) {
        var surahData = Map<String, dynamic>.from(surahsData[i]);
        surahData['number'] = surahData['number'] ?? (i + 1);
        // Normalize for Surah.fromJson
        surahData['surahName'] = surahData['surahName'] ?? surahData['name'] ?? '';
        surahData['surahNameArabic'] = surahData['surahNameArabic'] ?? surahData['nameArabic'] ?? '';
        surahData['surahNameArabicLong'] = surahData['surahNameArabicLong'] ?? surahData['nameArabicLong'] ?? '';
        surahData['surahNameTranslation'] = surahData['surahNameTranslation'] ?? surahData['nameTranslation'] ?? '';
        surahData['revelationPlace'] = surahData['revelationPlace'] ?? surahData['revelation'] ?? '';
        surahData['totalAyah'] = surahData['totalAyah'] ?? surahData['ayahCount'] ?? 0;

        _cachedSurahs!.add(Surah.fromJson(surahData));
      }

      // Write-through to DB
      await _repo.putSurahIndexBatch(_cachedSurahs!
          .map((s) => {
                'number': s.number,
                'surahName': s.name,
                'surahNameArabic': s.nameArabic,
                'surahNameArabicLong': s.nameArabicLong,
                'surahNameTranslation': s.nameTranslation,
                'revelationPlace': s.revelationPlace,
                'totalAyah': s.totalAyah,
              })
          .toList());

      return _cachedSurahs!;
    } catch (e) {
      print('ERROR loading surahs from assets: $e');
      _cachedSurahs = _fallbackSurahs;
      return _fallbackSurahs;
    }
  }

  // Ensure a detail is in memory using only memory -> DB (no assets), for instant navigation
  Future<void> ensureDetailCached(int surahNumber) async {
    if (_cachedSurahDetails.containsKey(surahNumber)) return;
    try {
      final jsonMap = await _repo.getSurahDetail(surahNumber);
      if (jsonMap != null) {
        jsonMap['surahNo'] = jsonMap['surahNo'] ?? surahNumber;
        _cachedSurahDetails[surahNumber] = SurahDetail.fromJson(jsonMap);
      }
    } catch (_) {
      // Ignore here; asset fallback handled in getSurahDetail
    }
  }

  // Prefetch multiple details non-blocking from DB into memory (no assets)
  void prefetchDetailsFromDb(List<int> surahNumbers, {int batchSize = 12, Duration delay = const Duration(milliseconds: 30)}) {
    Future<void> _prefetchBatch(int start) async {
      final end = (start + batchSize) > surahNumbers.length ? surahNumbers.length : (start + batchSize);
      for (int i = start; i < end; i++) {
        final n = surahNumbers[i];
        if (!_cachedSurahDetails.containsKey(n)) {
          await ensureDetailCached(n);
        }
      }
      if (end < surahNumbers.length) {
        Future.delayed(delay, () => _prefetchBatch(end));
      }
    }

    if (surahNumbers.isNotEmpty) {
      _prefetchBatch(0);
    }
  }

  Future<SurahDetail> getSurahDetail(int surahNumber) async {
    // Memory
    final cached = _cachedSurahDetails[surahNumber];
    if (cached != null) return cached;

    // DB
    try {
      final jsonMap = await _repo.getSurahDetail(surahNumber);
      if (jsonMap != null) {
        // Ensure consistency
        jsonMap['surahNo'] = jsonMap['surahNo'] ?? surahNumber;
        final detail = SurahDetail.fromJson(jsonMap);
        _cachedSurahDetails[surahNumber] = detail;
        return detail;
      }
    } catch (e) {
      print('DB read for surah detail $surahNumber failed, will try assets: $e');
    }

    // Assets fallback (write-through)
    try {
      final String data = await rootBundle.loadString('assets/data/surah_$surahNumber.json');
      final Map<String, dynamic> surahData = json.decode(data);
      surahData['surahNo'] = surahData['surahNo'] ?? surahNumber;

      // Write-through to DB
      await _repo.putSurahDetail(surahNumber, surahData);

      final detail = SurahDetail.fromJson(surahData);
      _cachedSurahDetails[surahNumber] = detail;
      return detail;
    } catch (e) {
      print('ERROR loading details for surah $surahNumber from assets: $e');
      return _getDefaultFallbackSurahDetail(surahNumber);
    }
  }

  // Fallback Al-Fatiha
  SurahDetail _getDefaultFallbackSurahDetail(int surahNumber) {
    if (_cachedSurahDetails.containsKey(1)) {
      return _cachedSurahDetails[1]!;
    }

    final arabicVerses = [
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'الرَّحْمَٰنِ الرَّحِيمِ',
      'مَالِكِ يَوْمِ الدِّينِ',
      'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ'
    ];
    final englishVerses = [
      'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      'All praise is due to Allah, Lord of the worlds.',
      'The Entirely Merciful, the Especially Merciful,',
      'Sovereign of the Day of Recompense.',
      'It is You we worship and You we ask for help.',
      'Guide us to the straight path -',
      'The path of those upon whom You have bestowed favor, not of those who have evoked anger or of those who are astray.'
    ];
    final bengaliVerses = [
      'পরম করুণাময় অতি দয়ালু আল্লাহর নামে',
      'সকল প্রশংসা আল্লাহর জন্য, যিনি সমস্ত জগতের প্রতিপালক',
      'পরম করুণাময়, অতি দয়ালু',
      'বিচার দিনের মালিক',
      'আমরা কেবল তোমারই ইবাদত করি এবং তোমারই সাহায্য প্রার্থনা করি',
      'আমাদেরকে সরল পথে পরিচালিত কর',
      'তাদের পথে যাদেরকে তুমি নিয়ামত দান করেছ, তাদের নয় যাদের প্রতি তোমার রোষ হয়েছে এবং যারা পথভ্রষ্ট'
    ];

    final ayahs = List<Ayah>.generate(7, (i) {
      return Ayah(
        number: i + 1,
        arabic: arabicVerses[i],
        english: englishVerses[i],
        bengali: bengaliVerses[i],
      );
    });

    final fallback = SurahDetail(
      surahName: 'Al-Faatiha',
      surahNameArabic: 'الفاتحة',
      surahNameArabicLong: 'سُورَةُ ٱلْفَاتِحَةِ',
      surahNameTranslation: 'The Opening',
      revelationPlace: 'Mecca',
      totalAyah: 7,
      surahNo: 1,
      english: englishVerses,
      arabic1: arabicVerses,
      bengali: bengaliVerses,
      ayahs: ayahs,
    );
    _cachedSurahDetails[1] = fallback;
    return fallback;
  }

  // Preloading counters no longer represent true caching state; keep for compatibility
  final RxInt _preloadedCount = 0.obs;
  int get preloadedCount => _preloadedCount.value;

  // Checks how many surahs are cached (details loaded in memory)
  int get cachedSurahCount => _cachedSurahDetails.length;

  void recordPreloadedSurah() {
    _preloadedCount.value++;
  }
}
