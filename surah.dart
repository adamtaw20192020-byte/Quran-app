class Surah {
  final int number;
  final String name; // الاسم بالعربية
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType; // Meccan / Medinan

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
    );
  }

  String get revelationTypeArabic =>
      revelationType == 'Meccan' ? 'مكية' : 'مدنية';
}
