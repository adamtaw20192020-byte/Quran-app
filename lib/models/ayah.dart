class Ayah {
  final int number; // الرقم العام في القرآن
  final int numberInSurah;
  final String text;
  final int surahNumber;
  final String surahName;
  String? translation;
  String? audioUrl;

  Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.surahNumber,
    required this.surahName,
    this.translation,
    this.audioUrl,
  });

  factory Ayah.fromJson(Map<String, dynamic> json, {String? surahName}) {
    return Ayah(
      number: json['number'] as int,
      numberInSurah: json['numberInSurah'] as int,
      text: json['text'] as String,
      surahNumber: (json['surah']?['number'] ?? 0) as int,
      surahName: surahName ?? (json['surah']?['name'] ?? '') as String,
    );
  }

  // مفتاح فريد لاستخدامه في حفظ المفضلة محلياً
  String get bookmarkKey => 'ayah_${surahNumber}_$numberInSurah';

  // رابط صوت احتياطي (تلاوة مشاري العفاسي) يُبنى من رقم الآية العام
  // يُستخدم فقط إذا لم يصل audioUrl من الـ API لأي سبب
  String get fallbackAudioUrl =>
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3';
}
