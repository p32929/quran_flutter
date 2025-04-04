import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import '../services/quran_hive_service.dart';

class QuranController extends GetxController {
  final QuranHiveService _quranService = Get.find<QuranHiveService>();
  
  // Main data
  final RxList<Surah> surahs = <Surah>[].obs;
  final Rx<SurahDetail?> currentSurahDetail = Rx<SurahDetail?>(null);
  
  // Filtered data
  final RxList<Surah> filteredSurahs = <Surah>[].obs;
  
  // Status indicators
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Global preloading state
  final RxBool isPreloading = true.obs;
  final RxInt preloadedCount = 0.obs;
  final int totalSurahCount = 114;
  
  // Cache complete indicator
  final RxBool isCacheComplete = false.obs;
  
  // Search query
  final RxString searchQuery = ''.obs;
  
  // Timer to periodically check preloading status
  Timer? _preloadingTimer;
  
  @override
  void onInit() {
    super.onInit();
    
    // Start observing initialization state
    ever(_quranService.isInitialized, _onServiceInitialized);
    
    // If service is already initialized, fetch data right away
    if (_quranService.isInitialized.value) {
      _onServiceInitialized(true);
    }
  }
  
  // Called when service is initialized
  void _onServiceInitialized(bool isInit) {
    if (isInit) {
      // Set the cache completion flag
      isCacheComplete.value = _quranService.isFullCacheLoaded.value;
      
      // Bind local value to service value for reactivity
      ever(_quranService.isFullCacheLoaded, (value) {
        isCacheComplete.value = value;
        if (value) {
          isPreloading.value = false;  // Stop preloading indicator when cache is complete
        }
      });
      
      // Start fetching data
      fetchSurahs();
      
      // Start monitoring preloading status
      _startPreloadingMonitor();
    }
  }
  
  @override
  void onClose() {
    _preloadingTimer?.cancel();
    super.onClose();
  }
  
  // Start monitoring the preloading progress
  void _startPreloadingMonitor() {
    // Update preloaded count initially
    preloadedCount.value = _quranService.cachedSurahCount;
    
    // Check every 300ms until all surahs are preloaded
    _preloadingTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      // Update the preloaded count
      preloadedCount.value = _quranService.cachedSurahCount;
      
      // If all surahs are preloaded or cache is complete, stop monitoring
      if (preloadedCount.value >= totalSurahCount || isCacheComplete.value) {
        isPreloading.value = false;
        timer.cancel();
        print('All surahs preloaded or cache completed. Preloading complete.');
      }
    });
  }
  
  // Fetch list of surahs from local assets
  Future<void> fetchSurahs() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    
    try {
      // Use the service to get surahs
      final surahsList = await _quranService.getSurahs();
      surahs.value = surahsList;
      
      // Initialize filtered list
      filteredSurahs.value = List.from(surahs);
      
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error loading surahs: $e');
    }
  }
  
  // Pre-load a surah detail without showing the loading state
  // This is used for pre-loading before navigation to ensure instant display
  Future<SurahDetail?> preloadSurahDetail(int surahNumber) async {
    try {
      // Use the QuranService to get surah details
      return await _quranService.getSurahDetail(surahNumber);
    } catch (e) {
      print('Error preloading surah detail for surah $surahNumber: $e');
      return null;
    }
  }
  
  // Fetch details for a specific surah
  Future<void> fetchSurahDetail(int surahNumber) async {
    // Only show loading if not already cached
    if (!_quranService.isSurahLoaded(surahNumber)) {
      isLoading.value = true;
    }
    
    hasError.value = false;
    errorMessage.value = '';
    
    try {
      // Use the QuranService to get surah details
      final surahDetail = await _quranService.getSurahDetail(surahNumber);
      
      // Update the current surah detail
      currentSurahDetail.value = surahDetail;
      print('Successfully loaded surah detail for surah $surahNumber');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error loading surah data. Please restart the app.';
      print('Error loading surah detail for surah $surahNumber: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Check if a specific surah is already fully loaded
  bool isSurahLoaded(int surahNumber) {
    return _quranService.isSurahLoaded(surahNumber);
  }
  
  // Get ayahs from current surah detail
  List<Ayah> get ayahs {
    return currentSurahDetail.value?.ayahs ?? [];
  }
  
  // Filter surahs based on search query
  void filterSurahs(String query) {
    searchQuery.value = query;
    
    if (query.isEmpty) {
      filteredSurahs.value = List.from(surahs);
      return;
    }
    
    final String lowercaseQuery = query.toLowerCase();
    
    filteredSurahs.value = surahs.where((surah) {
      return 
        surah.name.toLowerCase().contains(lowercaseQuery) ||
        surah.nameTranslation.toLowerCase().contains(lowercaseQuery) ||
        surah.number.toString() == query;
    }).toList();
  }
  
  // Get a single surah by number
  Surah? getSurahByNumber(int number) {
    try {
      return surahs.firstWhere((surah) => surah.number == number);
    } catch (e) {
      return null;
    }
  }
  
  // Force start a background preload of all surahs
  void startBackgroundPreload() {
    _quranService.preloadAllSurahs();
  }
} 