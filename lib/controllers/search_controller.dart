import 'package:get/get.dart';
import '../models/ayah_model.dart';
import '../services/quran_service.dart';
import '../models/surah_model.dart';

class AyahSearchResult {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;

  AyahSearchResult({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
  });
}

class SearchController extends GetxController {
  final QuranService _quranService = Get.find<QuranService>();
  
  // Search state
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxList<AyahSearchResult> searchResults = <AyahSearchResult>[].obs;
  final RxBool hasResults = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Search settings
  final RxBool searchInArabic = true.obs;
  final RxBool searchInEnglish = true.obs;
  final RxBool searchInBengali = true.obs;
  
  // Cached surahs for faster search
  final Map<int, SurahDetail> _cachedSurahDetails = {};
  List<Surah>? _surahs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize by loading surahs
    _loadSurahs();
  }
  
  Future<void> _loadSurahs() async {
    try {
      _surahs = await _quranService.getSurahs();
    } catch (e) {
      print('Error loading surahs in search controller: $e');
    }
  }
  
  // Search across all ayahs
  Future<void> searchAyahs(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      hasResults.value = false;
      return;
    }
    
    isSearching.value = true;
    hasError.value = false;
    searchQuery.value = query;
    
    try {
      // Clear previous results
      searchResults.clear();
      
      // Ensure surahs are loaded
      if (_surahs == null) {
        await _loadSurahs();
      }
      
      // If still null, report error
      if (_surahs == null) {
        hasError.value = true;
        errorMessage.value = 'Failed to load Quran data for search';
        isSearching.value = false;
        return;
      }
      
      // Normalize search query
      final String normalizedQuery = query.toLowerCase().trim();
      
      // Search through all surahs
      for (final surah in _surahs!) {
        await _searchInSurah(surah, normalizedQuery);
      }
      
      hasResults.value = searchResults.isNotEmpty;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error during search: $e';
      print('Search error: $e');
    } finally {
      isSearching.value = false;
    }
  }
  
  // Search within a specific surah
  Future<void> _searchInSurah(Surah surah, String query) async {
    try {
      // Get or load surah details
      SurahDetail surahDetail;
      if (_cachedSurahDetails.containsKey(surah.number)) {
        surahDetail = _cachedSurahDetails[surah.number]!;
      } else {
        surahDetail = await _quranService.getSurahDetail(surah.number);
        _cachedSurahDetails[surah.number] = surahDetail;
      }
      
      // Search through each ayah in the surah
      for (final ayah in surahDetail.ayahs) {
        if (_ayahMatchesQuery(ayah, query)) {
          searchResults.add(AyahSearchResult(
            ayah: ayah,
            surahNumber: surah.number,
            surahName: surah.name,
          ));
        }
      }
    } catch (e) {
      print('Error searching in surah ${surah.number}: $e');
    }
  }
  
  // Check if an ayah matches the search query
  bool _ayahMatchesQuery(Ayah ayah, String query) {
    if (searchInArabic.value && ayah.arabic.toLowerCase().contains(query)) {
      return true;
    }
    
    if (searchInEnglish.value && ayah.english.toLowerCase().contains(query)) {
      return true;
    }
    
    if (searchInBengali.value && ayah.bengali.toLowerCase().contains(query)) {
      return true;
    }
    
    return false;
  }
  
  // Toggle search language settings
  void toggleArabicSearch() {
    searchInArabic.value = !searchInArabic.value;
    // If all are disabled, enable at least one
    if (!searchInArabic.value && !searchInEnglish.value && !searchInBengali.value) {
      searchInArabic.value = true;
    }
  }
  
  void toggleEnglishSearch() {
    searchInEnglish.value = !searchInEnglish.value;
    // If all are disabled, enable at least one
    if (!searchInArabic.value && !searchInEnglish.value && !searchInBengali.value) {
      searchInEnglish.value = true;
    }
  }
  
  void toggleBengaliSearch() {
    searchInBengali.value = !searchInBengali.value;
    // If all are disabled, enable at least one
    if (!searchInArabic.value && !searchInEnglish.value && !searchInBengali.value) {
      searchInBengali.value = true;
    }
  }
  
  // Clear search results
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    hasResults.value = false;
  }
} 