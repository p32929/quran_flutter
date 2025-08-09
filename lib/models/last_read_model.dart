class LastRead {
  final int surah;
  final int verse;

  LastRead({required this.surah, required this.verse});

  factory LastRead.fromJson(Map<String, dynamic> json) {
    return LastRead(
      surah: json['surah'],
      verse: json['verse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'verse': verse,
    };
  }
}
