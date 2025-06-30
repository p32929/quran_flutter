class Ayah {
  final int number;
  final String arabic;
  final String english;
  final String bengali;

  Ayah({
    required this.number,
    required this.arabic,
    required this.english,
    required this.bengali,
  });

  factory Ayah.fromJson(Map<String, dynamic> json, int index) {
    return Ayah(
      number: index + 1,
      arabic: json['arabic1'] != null && json['arabic1'].length > index 
          ? json['arabic1'][index] 
          : '',
      english: json['english'] != null && json['english'].length > index 
          ? json['english'][index] 
          : '',
      bengali: json['bengali'] != null && json['bengali'].length > index 
          ? json['bengali'][index] 
          : '',
    );
  }
}

// New model for the surah details
class SurahDetail {
  final String surahName;
  final String surahNameArabic;
  final String surahNameArabicLong;
  final String surahNameTranslation;
  final String revelationPlace;
  final int totalAyah;
  final int surahNo;
  final List<String> english;
  final List<String> arabic1;
  final List<String> bengali;
  final List<Ayah> ayahs;
  final Map<String, dynamic>? rawData;

  SurahDetail({
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNameArabicLong,
    required this.surahNameTranslation,
    required this.revelationPlace,
    required this.totalAyah,
    required this.surahNo,
    required this.english,
    required this.arabic1,
    required this.bengali,
    required this.ayahs,
    this.rawData,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    // Extract verse arrays
    List<String> englishVerses = List<String>.from(json['english'] ?? []);
    List<String> arabicVerses = List<String>.from(json['arabic1'] ?? []);
    List<String> bengaliVerses = List<String>.from(json['bengali'] ?? []);

    // Create ayahs list
    List<Ayah> ayahsList = [];
    for (int i = 0; i < (json['totalAyah'] ?? 0); i++) {
      ayahsList.add(Ayah(
        number: i + 1,
        arabic: i < arabicVerses.length ? arabicVerses[i] : '',
        english: i < englishVerses.length ? englishVerses[i] : '',
        bengali: i < bengaliVerses.length ? bengaliVerses[i] : '',
      ));
    }

    return SurahDetail(
      surahName: json['surahName'] ?? '',
      surahNameArabic: json['surahNameArabic'] ?? '',
      surahNameArabicLong: json['surahNameArabicLong'] ?? '',
      surahNameTranslation: json['surahNameTranslation'] ?? '',
      revelationPlace: json['revelationPlace'] ?? '',
      totalAyah: json['totalAyah'] ?? 0,
      surahNo: json['surahNo'] ?? 0,
      english: englishVerses,
      arabic1: arabicVerses,
      bengali: bengaliVerses,
      ayahs: ayahsList,
      rawData: json,
    );
  }
} 