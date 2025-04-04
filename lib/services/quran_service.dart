import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import 'quran_hive_service.dart';

class QuranService extends GetxService {
  // Use the QuranHiveService for implementation
  QuranHiveService get _hiveService => Get.find<QuranHiveService>();
  
  // No need to access private members directly

  @override
  void onInit() {
    super.onInit();
    // Initialization is now handled by QuranHiveService
  }

  // Delegate to QuranHiveService
  Future<List<Surah>> getSurahs() async {
    return _hiveService.getSurahs();
  }

  // Delegate to QuranHiveService
  Future<SurahDetail> getSurahDetail(int surahNumber) async {
    return _hiveService.getSurahDetail(surahNumber);
  }

  // Proxy public methods for compatibility
  int get preloadedCount => _hiveService.preloadedCount;

  // Checks how many surahs are cached
  int get cachedSurahCount => _hiveService.cachedSurahCount;

  // Record preloading status for a surah (now a no-op)
  void recordPreloadedSurah() {
    // This functionality is now handled by QuranHiveService
  }
  
  // Proxy for checking if a surah is loaded
  bool isSurahLoaded(int surahNumber) {
    return _hiveService.isSurahLoaded(surahNumber);
  }
  
  // Proxy for preloading all surahs
  void preloadAllSurahs() {
    _hiveService.preloadAllSurahs();
  }
}
