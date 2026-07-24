class TranslationEdition {
  final String id;
  final String language; // display name, e.g. "Bengali"
  final String languageCode; // e.g. "bengali"
  final String direction; // "ltr" | "rtl"
  final String translator;
  final String title; // short title in the edition's own language
  final String description;

  const TranslationEdition({
    required this.id,
    required this.language,
    required this.languageCode,
    required this.direction,
    required this.translator,
    required this.title,
    required this.description,
  });

  bool get isRtl => direction == 'rtl';

  factory TranslationEdition.fromJson(Map<String, dynamic> json) {
    return TranslationEdition(
      id: json['id'] ?? '',
      language: json['language'] ?? '',
      languageCode: json['languageCode'] ?? '',
      direction: json['direction'] ?? 'ltr',
      translator: json['translator'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
