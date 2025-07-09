import 'dart:convert';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import '../models/bookmark_model.dart';
import '../models/ayah_model.dart';

class BookmarkController extends GetxController {
  static const String BOOKMARKS_KEY = 'quran_bookmarks';
  
  final RxList<Bookmark> bookmarks = <Bookmark>[].obs;
  late final BasePrefService _prefService;
  
  @override
  void onInit() {
    super.onInit();
    _prefService = Get.find<BasePrefService>();
    loadBookmarks();
  }
  
  // Load bookmarks from local storage
  Future<void> loadBookmarks() async {
    try {
      final String? bookmarksJson = _prefService.get(BOOKMARKS_KEY);
      
      if (bookmarksJson != null) {
        final List<dynamic> decodedList = json.decode(bookmarksJson);
        final List<Bookmark> loadedBookmarks = decodedList
            .map((item) => Bookmark.fromMap(item as Map<String, dynamic>))
            .toList();
        
        bookmarks.value = loadedBookmarks;
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }
  
  // Save bookmarks to local storage
  Future<void> saveBookmarks() async {
    try {
      final String encodedList = json.encode(
        bookmarks.map((bookmark) => bookmark.toMap()).toList(),
      );
      
      await _prefService.set(BOOKMARKS_KEY, encodedList);
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }
  
  // Add bookmark for an ayah
  void toggleBookmark(Ayah ayah, int surahNumber, String surahName) {
    // Check if already bookmarked
    final existingIndex = bookmarks.indexWhere(
      (item) => item.surahNumber == surahNumber && item.ayahNumber == ayah.number,
    );
    
    if (existingIndex >= 0) {
      // Remove bookmark if it exists
      bookmarks.removeAt(existingIndex);
    } else {
      // Add new bookmark
      bookmarks.add(Bookmark(
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: ayah.number,
        ayahText: ayah.arabic,
        translation: ayah.english,
      ));
    }
    
    // Save changes
    saveBookmarks();
    // Add update to refresh UI
    update();
  }
  
  // Check if an ayah is bookmarked
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return bookmarks.any(
      (item) => item.surahNumber == surahNumber && item.ayahNumber == ayahNumber,
    );
  }
  
  // Check if a surah has any bookmarks
  bool hasBookmarksForSurah(int surahNumber) {
    return bookmarks.any((item) => item.surahNumber == surahNumber);
  }
  
  // Remove a specific bookmark
  void removeBookmark(int surahNumber, int ayahNumber) {
    bookmarks.removeWhere(
      (item) => item.surahNumber == surahNumber && item.ayahNumber == ayahNumber,
    );
    saveBookmarks();
    // Add update to refresh UI
    update();
  }
  
  // Clear all bookmarks
  void clearAllBookmarks() {
    bookmarks.clear();
    saveBookmarks();
    // Add update to refresh UI
    update();
  }
} 