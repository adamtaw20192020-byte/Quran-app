import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';

/// خدمة مركزية للتعامل مع alquran.cloud API
/// كل الدوال ترمي Exception عند الفشل مع رسالة واضحة بالعربية
class QuranApiService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  // المصحف بالنص العثماني
  static const String quranEdition = 'quran-uthmani';
  // ترجمة إنجليزية معتمدة (يمكن تغييرها لاحقاً حسب رغبة المستخدم)
  static const String defaultTranslationEdition = 'en.sahih';

  // تلاوة صوتية بصوت الشيخ مشاري العفاسي (128kbps)
  static const String defaultAudioEdition = 'ar.alafasy';

  Future<List<Surah>> getAllSurahs() async {
    final uri = Uri.parse('$_baseUrl/surah');
    final response = await _getWithTimeout(uri);

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw Exception('تعذر جلب قائمة السور من الخادم');
    }

    final List<dynamic> data = body['data'] as List<dynamic>;
    return data.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// يجلب آيات سورة معيّنة مع النص العربي، ويدمج معها الترجمة والصوت إن طُلبت
  Future<List<Ayah>> getSurahAyahs(
    int surahNumber, {
    bool withTranslation = true,
    bool withAudio = true,
    String translationEdition = defaultTranslationEdition,
    String audioEdition = defaultAudioEdition,
  }) async {
    // نبني قائمة الإصدارات: النص العربي أولاً، ثم الترجمة (إن وُجدت)، ثم الصوت (إن وُجد)
    final editionsList = [quranEdition];
    if (withTranslation) editionsList.add(translationEdition);
    if (withAudio) editionsList.add(audioEdition);
    final editions = editionsList.join(',');

    final uri = Uri.parse('$_baseUrl/surah/$surahNumber/editions/$editions');
    final response = await _getWithTimeout(uri);

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw Exception('تعذر جلب آيات السورة رقم $surahNumber');
    }

    final List<dynamic> data = body['data'] as List<dynamic>;
    final arabicData = data[0] as Map<String, dynamic>;
    final surahName = arabicData['name'] as String;
    final List<dynamic> arabicAyahs = arabicData['ayahs'] as List<dynamic>;

    final ayahs = arabicAyahs
        .map((e) => Ayah.fromJson(e as Map<String, dynamic>, surahName: surahName))
        .toList();

    // ترتيب باقي الإصدارات في data يطابق ترتيب editionsList بعد النص العربي
    var nextIndex = 1;

    if (withTranslation && data.length > nextIndex) {
      final translationData = data[nextIndex] as Map<String, dynamic>;
      final List<dynamic> translationAyahs =
          translationData['ayahs'] as List<dynamic>;
      for (var i = 0; i < ayahs.length && i < translationAyahs.length; i++) {
        ayahs[i].translation = translationAyahs[i]['text'] as String;
      }
      nextIndex++;
    }

    if (withAudio && data.length > nextIndex) {
      final audioData = data[nextIndex] as Map<String, dynamic>;
      final List<dynamic> audioAyahs = audioData['ayahs'] as List<dynamic>;
      for (var i = 0; i < ayahs.length && i < audioAyahs.length; i++) {
        ayahs[i].audioUrl = audioAyahs[i]['audio'] as String?;
      }
    }

    return ayahs;
  }

  /// بحث نصي داخل القرآن (بالعربية أو حسب لغة النسخة المحددة)
  Future<List<Ayah>> search(
    String keyword, {
    String edition = quranEdition,
  }) async {
    if (keyword.trim().isEmpty) return [];

    final encoded = Uri.encodeComponent(keyword.trim());
    final uri = Uri.parse('$_baseUrl/search/$encoded/all/$edition');
    final response = await _getWithTimeout(uri);

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200) {
      // 404 يعني عدم وجود نتائج - ليست خطأ فعلي
      if (body['code'] == 404) return [];
      throw Exception('حدث خطأ أثناء البحث');
    }

    final matches = (body['data']?['matches'] ?? []) as List<dynamic>;
    return matches.map((m) {
      final map = m as Map<String, dynamic>;
      return Ayah(
        number: map['number'] as int,
        numberInSurah: map['numberInSurah'] as int,
        text: map['text'] as String,
        surahNumber: (map['surah']?['number'] ?? 0) as int,
        surahName: (map['surah']?['name'] ?? '') as String,
      );
    }).toList();
  }

  Future<http.Response> _getWithTimeout(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw Exception('فشل الاتصال بالخادم (كود ${response.statusCode})');
      }
      return response;
    } on Exception catch (e) {
      throw Exception('لا يوجد اتصال بالإنترنت أو الخادم لا يستجيب: $e');
    }
  }
}
