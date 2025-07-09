class Bookmark {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String translation;
  
  Bookmark({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.translation,
  });
  
  // Create from Map (for SharedPreferences storage)
  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      surahNumber: map['surahNumber'] as int,
      surahName: map['surahName'] as String,
      ayahNumber: map['ayahNumber'] as int,
      ayahText: map['ayahText'] as String,
      translation: map['translation'] as String,
    );
  }
  
  // Convert to Map (for SharedPreferences storage)
  Map<String, dynamic> toMap() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'ayahText': ayahText,
      'translation': translation,
    };
  }
  
  // Create a unique ID for this bookmark
  String get id => '$surahNumber:$ayahNumber';
  
  @override
  String toString() {
    return 'Bookmark($surahNumber:$ayahNumber - $surahName)';
  }
} 