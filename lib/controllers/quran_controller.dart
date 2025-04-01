import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import '../services/quran_service.dart';

class QuranController extends GetxController {
  // Use late initialization to delay finding the service
  late final QuranService _quranService;
  
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
  
  // Search query
  final RxString searchQuery = ''.obs;
  
  // Timer to periodically check preloading status
  Timer? _preloadingTimer;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize the service here
    _quranService = Get.find<QuranService>();
    fetchSurahs();
    
    // Start monitoring preloading status
    _startPreloadingMonitor();
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
    
    // Check every 500ms until all surahs are preloaded
    _preloadingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Update the preloaded count
      preloadedCount.value = _quranService.cachedSurahCount;
      
      // If all surahs are preloaded, stop monitoring
      if (preloadedCount.value >= totalSurahCount) {
        isPreloading.value = false;
        timer.cancel();
        print('All surahs preloaded. Preloading complete.');
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
  
  // Fetch details for a specific surah
  Future<void> fetchSurahDetail(int surahNumber) async {
    // Don't show loading if we have data already (avoid flickering)
    final bool hadDataBefore = currentSurahDetail.value != null;
    if (!hadDataBefore) {
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
    return _quranService.cachedSurahCount >= surahNumber;
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
} 