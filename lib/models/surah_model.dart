class Surah {
  final int number;
  final String name;
  final String nameArabic;
  final String nameArabicLong;
  final String nameTranslation;
  final String revelationPlace;
  final int totalAyah;

  Surah({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.nameArabicLong, 
    required this.nameTranslation,
    required this.totalAyah,
    required this.revelationPlace,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0, // Fallback to 0 if number is not provided
      name: json['surahName'] ?? '',
      nameArabic: json['surahNameArabic'] ?? '',
      nameArabicLong: json['surahNameArabicLong'] ?? '',
      nameTranslation: json['surahNameTranslation'] ?? '',
      totalAyah: json['totalAyah'] ?? 0,
      revelationPlace: json['revelationPlace'] ?? '',
    );
  }
} 