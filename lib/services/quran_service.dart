import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

class QuranService extends GetxService {
  // Cache for loaded data
  final Map<int, SurahDetail> _cachedSurahDetails = {};
  List<Surah>? _cachedSurahs;
  
  // Fallback data for when assets fail to load
  final List<Surah> _fallbackSurahs = [
    Surah(
      number: 1,
      name: 'Al-Faatiha',
      nameArabic: 'الفاتحة',
      nameArabicLong: 'سُورَةُ ٱلْفَاتِحَةِ',
      nameTranslation: 'The Opening',
      totalAyah: 7,
      revelationPlace: 'Mecca'
    ),
    Surah(
      number: 2,
      name: 'Al-Baqara',
      nameArabic: 'البقرة',
      nameArabicLong: 'سورة البقرة',
      nameTranslation: 'The Cow',
      totalAyah: 286,
      revelationPlace: 'Madina'
    ),
    // More fallback surahs would be added here in production
  ];
  
  @override
  void onInit() {
    super.onInit();
    // Preload surahs data
    getSurahs();
  }
  
  Future<List<Surah>> getSurahs() async {
    // Return cached data if available
    if (_cachedSurahs != null) {
      print('Returning cached surahs: ${_cachedSurahs!.length}');
      return _cachedSurahs!;
    }
    
    try {
      print('Loading surahs.json from assets...');
      // Load from local assets
      final String data = await rootBundle.loadString('assets/data/surahs.json');
      print('surahs.json loaded, length: ${data.length}');
      
      final List<dynamic> surahsData = json.decode(data);
      print('JSON decoded successfully: ${surahsData.length} surahs found');
      
      // Add the surah number to each surah object since it's not in the JSON
      _cachedSurahs = [];
      for (int i = 0; i < surahsData.length; i++) {
        var surahData = Map<String, dynamic>.from(surahsData[i]);
        surahData['number'] = i + 1; // Add the surah number (1-indexed)
        _cachedSurahs!.add(Surah.fromJson(surahData));
      }
      
      print('Surahs parsed: ${_cachedSurahs!.length}');
      return _cachedSurahs!;
    } catch (e) {
      print('ERROR loading surahs: $e');
      // Fallback to hard-coded data when assets fail to load
      print('Using fallback surah data');
      _cachedSurahs = _fallbackSurahs;
      return _fallbackSurahs;
    }
  }

  Future<SurahDetail> getSurahDetail(int surahNumber) async {
    // Return cached data if available
    if (_cachedSurahDetails.containsKey(surahNumber)) {
      print('Returning cached surah detail for surah $surahNumber');
      return _cachedSurahDetails[surahNumber]!;
    }
    
    try {
      print('Loading details for surah $surahNumber from assets...');
      
      // Try up to 3 times to load from assets
      SurahDetail? surahDetail;
      int attempts = 0;
      bool success = false;
      Exception? lastError;
      
      while (!success && attempts < 3) {
        try {
          attempts++;
          // Load from local assets
          final String data = await rootBundle.loadString('assets/data/surah_$surahNumber.json');
          final Map<String, dynamic> surahData = json.decode(data);
          
          // Ensure surahNo is set
          if (!surahData.containsKey('surahNo')) {
            surahData['surahNo'] = surahNumber;
          }
          
          surahDetail = SurahDetail.fromJson(surahData);
          success = true;
          print('Successfully loaded surah detail $surahNumber');
        } catch (e) {
          print('Failed to load surah detail $surahNumber on attempt $attempts: $e');
          lastError = e as Exception;
          // Wait a short time before retrying
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      if (success && surahDetail != null) {
        // Cache for future use
        _cachedSurahDetails[surahNumber] = surahDetail;
        return surahDetail;
      } else {
        // If we couldn't load the surah after retries, log the error but don't crash
        print('ERROR: Failed to load surah detail $surahNumber after multiple attempts: $lastError');
        // Use a safe fallback approach - try to get a default surah detail
        return _getDefaultFallbackSurahDetail(surahNumber);
      }
    } catch (e) {
      print('ERROR loading details for surah $surahNumber: $e');
      return _getDefaultFallbackSurahDetail(surahNumber);
    }
  }
  
  // Provide a fallback for any surah that fails to load
  SurahDetail _getDefaultFallbackSurahDetail(int surahNumber) {
    // If we have at least surah 1 cached, return that as a fallback
    if (_cachedSurahDetails.containsKey(1)) {
      print('Using cached Al-Fatiha as fallback for surah $surahNumber');
      return _cachedSurahDetails[1]!;
    }
    
    // If all else fails, return a hardcoded Al-Fatiha
    print('Using hardcoded Al-Fatiha as fallback for surah $surahNumber');
    
    // Create a basic fallback Surah Al-Fatiha
    List<String> arabicVerses = [
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      'الرَّحْمَٰنِ الرَّحِيمِ',
      'مَالِكِ يَوْمِ الدِّينِ',
      'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ'
    ];
    
    List<String> englishVerses = [
      'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      'All praise is due to Allah, Lord of the worlds.',
      'The Entirely Merciful, the Especially Merciful,',
      'Sovereign of the Day of Recompense.',
      'It is You we worship and You we ask for help.',
      'Guide us to the straight path -',
      'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.'
    ];
    
    List<String> bengaliVerses = [
      'পরম করুণাময় অতি দয়ালু আল্লাহর নামে',
      'সকল প্রশংসা আল্লাহর জন্য, যিনি সমস্ত জগতের প্রতিপালক',
      'পরম করুণাময়, অতি দয়ালু',
      'বিচার দিনের মালিক',
      'আমরা কেবল তোমারই ইবাদত করি এবং তোমারই সাহায্য প্রার্থনা করি',
      'আমাদেরকে সরল পথে পরিচালিত কর',
      'তাদের পথে যাদেরকে তুমি নিয়ামত দান করেছ, তাদের নয় যাদের প্রতি তোমার রোষ হয়েছে এবং যারা পথভ্রষ্ট'
    ];
    
    // Create ayahs
    List<Ayah> ayahs = [];
    for (int i = 0; i < 7; i++) {
      ayahs.add(Ayah(
        number: i + 1,
        arabic: arabicVerses[i],
        english: englishVerses[i],
        bengali: bengaliVerses[i],
      ));
    }
    
    SurahDetail fallbackSurahDetail = SurahDetail(
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
    
    // Cache the fallback for future use
    _cachedSurahDetails[1] = fallbackSurahDetail;
    return fallbackSurahDetail;
  }
  
  // Track preloading progress
  final RxInt _preloadedCount = 0.obs;
  int get preloadedCount => _preloadedCount.value;
  
  // Checks how many surahs are cached
  int get cachedSurahCount => _cachedSurahDetails.length;
  
  // Record preloading status for a surah
  void recordPreloadedSurah() {
    _preloadedCount.value++;
  }
} 