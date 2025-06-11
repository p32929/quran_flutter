import 'package:get/get.dart';
import '../models/ayah_model.dart';
import '../services/quran_service.dart';
import '../models/surah_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AyahSearchResult {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;
  final String matchedText;
  final String matchLanguage;

  AyahSearchResult({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.matchedText,
    required this.matchLanguage,
  });
}

class SurahSearchResult {
  final Surah surah;
  final String matchedField;
  final double relevanceScore;

  SurahSearchResult({
    required this.surah,
    required this.matchedField,
    required this.relevanceScore,
  });
}

class SearchSuggestion {
  final String text;
  final String type; // 'recent', 'popular', 'topic', 'surah'
  final String? description;
  final dynamic data;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.description,
    this.data,
  });
}

class SearchController extends GetxController {
  final QuranService _quranService = Get.find<QuranService>();
  
  // Reactive variables
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchMode = 'unified'.obs; // 'unified', 'surahs', 'verses'
  
  // Language filters
  final searchInEnglish = true.obs;
  final searchInBengali = true.obs;
  
  // Search results
  final surahResults = <SurahSearchResult>[].obs;
  final ayahResults = <AyahSearchResult>[].obs;
  final suggestions = <SearchSuggestion>[].obs;
  final searchHistory = <String>[].obs;
  
  // UI states
  final showSuggestions = true.obs;
  final hasSearched = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
    _initializeSuggestions();
  }

  // Search methods
  void performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    searchQuery.value = query;
    isSearching.value = true;
    hasSearched.value = true;
    showSuggestions.value = false;
    
    await _addToSearchHistory(query);
    
    try {
      switch (searchMode.value) {
        case 'surahs':
          await _searchSurahs(query);
          break;
        case 'verses':
          await _searchVerses(query);
          break;
        default:
          await _performUnifiedSearch(query);
      }
    } finally {
      isSearching.value = false;
    }
  }
  
  void clearSearch() {
    searchQuery.value = '';
    surahResults.clear();
    ayahResults.clear();
    showSuggestions.value = true;
    hasSearched.value = false;
    _updateSuggestions('');
  }
  
  void onQueryChanged(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      clearSearch();
    } else {
      _updateSuggestions(query);
    }
  }
  
  // Search mode and filter methods
  void setSearchMode(String mode) {
    searchMode.value = mode;
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }
  
  void toggleEnglishSearch() {
    searchInEnglish.value = !searchInEnglish.value;
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }
  
  void toggleBengaliSearch() {
    searchInBengali.value = !searchInBengali.value;
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }

  // Private search implementation methods
  Future<void> _performUnifiedSearch(String query) async {
    await Future.wait([
      _searchSurahs(query),
      _searchVerses(query),
    ]);
  }
  
  Future<void> _searchSurahs(String query) async {
    final surahs = await _quranService.getSurahs();
    final results = <SurahSearchResult>[];
    
    for (final surah in surahs) {
      double relevanceScore = 0.0;
      String matchedField = '';
      
      // Search in surah name (English)
      if (surah.name.toLowerCase().contains(query.toLowerCase())) {
        relevanceScore += _calculateRelevanceScore(surah.name, query);
        matchedField = 'English name';
      }
      
      // Search in surah translation
      if (surah.nameTranslation.toLowerCase().contains(query.toLowerCase())) {
        relevanceScore += _calculateRelevanceScore(surah.nameTranslation, query);
        matchedField = matchedField.isEmpty ? 'Translation' : '$matchedField, Translation';
      }
      
      // Search by surah number
      if (surah.number.toString() == query) {
        relevanceScore += 100.0; // Exact number match gets highest score
        matchedField = 'Surah number';
      }
      
      if (relevanceScore > 0) {
        results.add(SurahSearchResult(
          surah: surah,
          matchedField: matchedField,
          relevanceScore: relevanceScore,
        ));
      }
    }
    
    // Sort by relevance score
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    surahResults.value = results;
  }
  
  Future<void> _searchVerses(String query) async {
    final allAyahs = <AyahSearchResult>[];
    final surahs = await _quranService.getSurahs();
    
    for (final surah in surahs) {
      try {
        final surahDetail = await _quranService.getSurahDetail(surah.number);
        
        for (final ayah in surahDetail.ayahs) {
          String? matchedText;
          String matchLanguage = '';
          
          // Search in English translation
          if (searchInEnglish.value && ayah.english.toLowerCase().contains(query.toLowerCase())) {
            matchedText = ayah.english;
            matchLanguage = 'English';
          }
          
          // Search in Bengali translation
          if (searchInBengali.value && ayah.bengali.toLowerCase().contains(query.toLowerCase())) {
            matchedText = ayah.bengali;
            matchLanguage = matchLanguage.isEmpty ? 'Bengali' : '$matchLanguage, Bengali';
          }
          
          if (matchedText != null) {
            allAyahs.add(AyahSearchResult(
            ayah: ayah,
            surahNumber: surah.number,
            surahName: surah.name,
              matchedText: matchedText,
              matchLanguage: matchLanguage,
          ));
        }
      }
    } catch (e) {
      print('Error searching in surah ${surah.number}: $e');
    }
  }
  
    ayahResults.value = allAyahs;
  }
  
  // Suggestion methods
  void _initializeSuggestions() {
    final popularSearches = [
      SearchSuggestion(text: 'mercy', type: 'popular', description: 'Verses about Allah\'s mercy'),
      SearchSuggestion(text: 'prayer', type: 'popular', description: 'Verses about prayer and worship'),
      SearchSuggestion(text: 'guidance', type: 'popular', description: 'Verses about divine guidance'),
      SearchSuggestion(text: 'patience', type: 'popular', description: 'Verses about patience and perseverance'),
      SearchSuggestion(text: 'Allah', type: 'popular', description: 'Verses mentioning Allah'),
      SearchSuggestion(text: 'believers', type: 'popular', description: 'Verses about believers'),
    ];
    
    final topicSuggestions = [
      SearchSuggestion(text: 'paradise', type: 'topic', description: 'Descriptions of paradise'),
      SearchSuggestion(text: 'forgiveness', type: 'topic', description: 'Verses about forgiveness'),
      SearchSuggestion(text: 'charity', type: 'topic', description: 'Verses about giving charity'),
      SearchSuggestion(text: 'wisdom', type: 'topic', description: 'Verses containing wisdom'),
      SearchSuggestion(text: 'righteous', type: 'topic', description: 'Verses about righteousness'),
      SearchSuggestion(text: 'peace', type: 'topic', description: 'Verses about peace'),
    ];
    
    final bengaliPopularSearches = [
      SearchSuggestion(text: 'দয়া', type: 'popular', description: 'আল্লাহর দয়া সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'নামাজ', type: 'popular', description: 'নামাজ ও ইবাদত সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'হেদায়েত', type: 'popular', description: 'পথনির্দেশনা সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'ধৈর্য', type: 'popular', description: 'ধৈর্য ও সহনশীলতা সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'আল্লাহ', type: 'popular', description: 'আল্লাহর উল্লেখ আছে এমন আয়াত'),
      SearchSuggestion(text: 'মুমিন', type: 'popular', description: 'মুমিনদের সম্পর্কে আয়াত'),
    ];
    
    final bengaliTopicSuggestions = [
      SearchSuggestion(text: 'জান্নাত', type: 'topic', description: 'জান্নাতের বর্ণনা'),
      SearchSuggestion(text: 'ক্ষমা', type: 'topic', description: 'ক্ষমা সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'দান', type: 'topic', description: 'দান-খয়রাত সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'জ্ঞান', type: 'topic', description: 'জ্ঞান ও হিকমত সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'সৎকর্ম', type: 'topic', description: 'সৎকর্ম সম্পর্কে আয়াত'),
      SearchSuggestion(text: 'শান্তি', type: 'topic', description: 'শান্তি সম্পর্কে আয়াত'),
    ];
    
    suggestions.value = [...popularSearches, ...topicSuggestions, ...bengaliPopularSearches, ...bengaliTopicSuggestions];
  }
  
  void _updateSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _initializeSuggestions();
      return;
    }
    
    final allSuggestions = <SearchSuggestion>[];
    
    // Add relevant search history
    final historyMatches = searchHistory.where((item) => 
        item.toLowerCase().contains(query.toLowerCase())).take(3);
    for (final match in historyMatches) {
      allSuggestions.add(SearchSuggestion(
        text: match,
        type: 'recent',
        description: 'Recent search',
      ));
    }
    
    // Add matching surahs
    try {
      final surahs = await _quranService.getSurahs();
      final surahMatches = surahs.where((surah) =>
          surah.name.toLowerCase().contains(query.toLowerCase()) ||
          surah.number.toString().contains(query)).take(3);
      for (final surah in surahMatches) {
        allSuggestions.add(SearchSuggestion(
          text: surah.name,
          type: 'surah',
          description: 'Surah ${surah.number} • ${surah.revelationPlace} • ${surah.totalAyah} verses',
          data: surah,
        ));
      }
    } catch (e) {
      print('Error getting surah suggestions: $e');
    }
    
    suggestions.value = allSuggestions;
  }
  
  // Utility methods
  double _calculateRelevanceScore(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (lowerText == lowerQuery) return 100.0;
    if (lowerText.startsWith(lowerQuery)) return 80.0;
    if (lowerText.contains(' $lowerQuery')) return 60.0;
    if (lowerText.contains(lowerQuery)) return 40.0;
    
    // Use Levenshtein distance for fuzzy matching
    final distance = _levenshteinDistance(lowerText, lowerQuery);
    final maxLength = lowerText.length > lowerQuery.length ? lowerText.length : lowerQuery.length;
    return ((maxLength - distance) / maxLength) * 20.0;
  }
  
  int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(s1.length + 1, 
        (i) => List.generate(s2.length + 1, (j) => 0));
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  // Search history methods
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      searchHistory.value = history;
    } catch (e) {
      print('Error loading search history: $e');
    }
  }
  
  Future<void> _addToSearchHistory(String query) async {
    try {
      var history = List<String>.from(searchHistory);
      
      // Remove if already exists to avoid duplicates
      history.remove(query);
      // Add to beginning
      history.insert(0, query);
      // Keep only last 10
      history = history.take(10).toList();
      
      searchHistory.value = history;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', history);
    } catch (e) {
      print('Error saving search history: $e');
    }
  }
  
  void clearSearchHistory() async {
    try {
      searchHistory.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
} 