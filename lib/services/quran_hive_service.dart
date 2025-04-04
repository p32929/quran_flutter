import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

class QuranHiveService extends GetxService {
  static const String QURAN_BOX = 'quran_box';
  static const String SURAHS_KEY = 'surahs';
  static const String SURAH_DETAILS_KEY_PREFIX = 'surah_';
  static const String FULL_CACHE_MARKER = 'full_cache_complete';
  
  // In-memory cache
  final Map<int, SurahDetail> _cachedSurahDetails = {};
  List<Surah>? _cachedSurahs;
  
  // Hive box
  Box? _quranBox;
  
  // Status indicators
  final RxBool isInitialized = false.obs;
  final RxBool isFullCacheLoaded = false.obs;
  final RxInt _preloadedCount = 0.obs;
  int get preloadedCount => _preloadedCount.value;
  int get cachedSurahCount => _cachedSurahDetails.length;
  
  // Initialize and prepare the service
  Future<QuranHiveService> init() async {
    if (!isInitialized.value) {
      await _initializeHive();
      isInitialized.value = true;
    }
    return this;
  }
  
  @override
  void onInit() {
    super.onInit();
    // The initialization now happens in init() method
    // which will be called explicitly before this service is used
  }
  
  // Initialize Hive and load pre-processed data
  Future<void> _initializeHive() async {
    try {
      print('Initializing Hive database...');
      
      // Open the box - make sure Hive is already initialized in main.dart
      try {
        _quranBox = await Hive.openBox(QURAN_BOX);
        print('Successfully opened Hive box: $QURAN_BOX');
      } catch (e) {
        print('Error opening Hive box: $e');
        // Try opening box with a delay - sometimes helps with web
        await Future.delayed(Duration(milliseconds: 500));
        _quranBox = await Hive.openBox(QURAN_BOX);
      }
      
      // Check if we already have data in the box
      if (_quranBox != null && _quranBox!.containsKey(FULL_CACHE_MARKER)) {
        print('Hive database already populated!');
        isFullCacheLoaded.value = true;
        await _loadSurahsFromHive();
      } else {
        // First time - load the pre-processed data
        await _loadPreProcessedData();
      }
      
      print('Hive initialization complete!');
    } catch (e) {
      print('Error initializing Hive: $e');
      // Fall back to traditional loading if Hive fails
      await _loadSurahsTraditionally();
    }
  }
  
  // Load pre-processed data into Hive
  Future<void> _loadPreProcessedData() async {
    try {
      print('Loading pre-processed Quran data into Hive...');
      
      // Load the data files
      final String surahsIndexJson = await rootBundle.loadString('assets/hive_data/surahs_index.json');
      final String quranDataJson = await rootBundle.loadString('assets/hive_data/quran_data.json');
      
      // Parse the JSON
      final List<dynamic> surahsData = json.decode(surahsIndexJson);
      final Map<String, dynamic> allSurahDetails = json.decode(quranDataJson);
      
      // Store surahs list in Hive
      await _quranBox!.put(SURAHS_KEY, surahsIndexJson);
      
      // Store individual surah details
      int processedCount = 0;
      for (var entry in allSurahDetails.entries) {
        int surahNumber = int.parse(entry.key);
        await _quranBox!.put('$SURAH_DETAILS_KEY_PREFIX$surahNumber', json.encode(entry.value));
        processedCount++;
        if (processedCount % 10 == 0) {
          print('Processed $processedCount surahs...');
        }
        _preloadedCount.value = processedCount;
      }
      
      // Mark as complete
      await _quranBox!.put(FULL_CACHE_MARKER, DateTime.now().toIso8601String());
      
      // Load surahs into memory
      _cachedSurahs = [];
      for (var surahData in surahsData) {
        _cachedSurahs!.add(Surah.fromJson(surahData));
      }
      
      isFullCacheLoaded.value = true;
      print('Finished loading ${_cachedSurahs!.length} surahs into Hive');
    } catch (e) {
      print('Error loading pre-processed data: $e');
      // Fall back to traditional loading
      await _loadSurahsTraditionally();
    }
  }
  
  // Load the surahs list from Hive
  Future<void> _loadSurahsFromHive() async {
    try {
      final String? surahsJson = _quranBox!.get(SURAHS_KEY);
      
      if (surahsJson != null) {
        final List<dynamic> surahsData = json.decode(surahsJson);
        
        _cachedSurahs = [];
        for (var surahData in surahsData) {
          _cachedSurahs!.add(Surah.fromJson(surahData));
        }
        
        print('Loaded ${_cachedSurahs!.length} surahs from Hive');
        
        // Count how many surah details we have
        int detailsCount = 0;
        for (int i = 1; i <= 114; i++) {
          if (_quranBox!.containsKey('$SURAH_DETAILS_KEY_PREFIX$i')) {
            detailsCount++;
          }
        }
        _preloadedCount.value = detailsCount;
        print('Found $detailsCount cached surah details');
      }
    } catch (e) {
      print('Error loading surahs from Hive: $e');
    }
  }
  
  // Fallback method to load surahs traditionally
  Future<void> _loadSurahsTraditionally() async {
    try {
      print('Falling back to traditional loading method');
      
      final String data = await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> surahsData = json.decode(data);
      
      _cachedSurahs = [];
      for (int i = 0; i < surahsData.length; i++) {
        var surahData = Map<String, dynamic>.from(surahsData[i]);
        surahData['number'] = i + 1;
        _cachedSurahs!.add(Surah.fromJson(surahData));
      }
      
      print('Loaded ${_cachedSurahs!.length} surahs traditionally');
    } catch (e) {
      print('Error in traditional loading: $e');
      _cachedSurahs = [];
    }
  }
  
  // Get all surahs
  Future<List<Surah>> getSurahs() async {
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }
    
    if (isInitialized.value) {
      await _loadSurahsFromHive();
    } else {
      await _loadSurahsTraditionally();
    }
    
    return _cachedSurahs ?? [];
  }
  
  // Get details for a specific surah
  Future<SurahDetail> getSurahDetail(int surahNumber) async {
    // Return from memory cache if available
    if (_cachedSurahDetails.containsKey(surahNumber)) {
      return _cachedSurahDetails[surahNumber]!;
    }
    
    try {
      // Try to get from Hive
      if (isInitialized.value && _quranBox != null) {
        final String? surahJson = _quranBox!.get('$SURAH_DETAILS_KEY_PREFIX$surahNumber');
        
        if (surahJson != null) {
          // Parse the JSON
          final Map<String, dynamic> surahData = json.decode(surahJson);
          
          // Create SurahDetail object
          final SurahDetail surahDetail = SurahDetail.fromJson(surahData);
          
          // Cache in memory
          _cachedSurahDetails[surahNumber] = surahDetail;
          
          return surahDetail;
        }
      }
      
      // If not in Hive, load from asset
      final String assetJson = await rootBundle.loadString('assets/data/surah_$surahNumber.json');
      final Map<String, dynamic> surahData = json.decode(assetJson);
      
      // Ensure surahNo is set
      if (!surahData.containsKey('surahNo')) {
        surahData['surahNo'] = surahNumber;
      }
      
      // Create SurahDetail object
      final SurahDetail surahDetail = SurahDetail.fromJson(surahData);
      
      // Cache in memory
      _cachedSurahDetails[surahNumber] = surahDetail;
      
      // Store in Hive for future use if initialized
      if (isInitialized.value && _quranBox != null) {
        await _quranBox!.put('$SURAH_DETAILS_KEY_PREFIX$surahNumber', assetJson);
      }
      
      return surahDetail;
    } catch (e) {
      print('Error loading surah $surahNumber: $e');
      throw Exception('Failed to load surah $surahNumber');
    }
  }
  
  // Check if a surah is loaded
  bool isSurahLoaded(int surahNumber) {
    return _cachedSurahDetails.containsKey(surahNumber);
  }
  
  // Preload all surahs in background
  void preloadAllSurahs() async {
    if (isFullCacheLoaded.value) return;
    
    print('Starting background preload of all surahs');
    for (int i = 1; i <= 114; i++) {
      if (!_cachedSurahDetails.containsKey(i)) {
        try {
          await getSurahDetail(i);
          _preloadedCount.value = _cachedSurahDetails.length;
        } catch (e) {
          print('Error preloading surah $i: $e');
        }
      }
    }
    
    isFullCacheLoaded.value = true;
    print('Background preload complete');
  }
} 