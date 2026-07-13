import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// خدمة الصوت الخاصة بتلاوة الشيخ ياسر الدوسري
///
/// المصدر: mp3quran.net - يوفر ملف صوتي واحد لكل سورة كاملة
/// نمط الرابط: https://server11.mp3quran.net/yasser/XXX.mp3
/// حيث XXX هو رقم السورة بثلاث خانات (مثال: 001.mp3 للفاتحة)
class AudioService {
  // نجعلها Singleton حتى يبقى نفس المشغل شغال بين الشاشات
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer player = AudioPlayer();

  static const String _reciterFolder = 'yasser';
  static const String _baseUrl = 'https://server11.mp3quran.net/yasser';

  String _surahFileName(int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    return '$padded.mp3';
  }

  String remoteUrl(int surahNumber) {
    return '$_baseUrl/${_surahFileName(surahNumber)}';
  }

  Future<Directory> _audioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/audio/$_reciterFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _localFile(int surahNumber) async {
    final dir = await _audioDirectory();
    return File('${dir.path}/${_surahFileName(surahNumber)}');
  }

  /// هل السورة محملة مسبقاً على الجهاز؟
  Future<bool> isDownloaded(int surahNumber) async {
    final file = await _localFile(surahNumber);
    return file.exists();
  }

  /// تحميل السورة كاملة على الجهاز، مع تقرير نسبة التقدم من 0.0 إلى 1.0
  Future<void> downloadSurah(
    int surahNumber, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await _localFile(surahNumber);
    final tempFile = File('${file.path}.tmp');

    final request = http.Request('GET', Uri.parse(remoteUrl(surahNumber)));
    final response = await http.Client().send(request).timeout(
          const Duration(seconds: 20),
        );

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الملف الصوتي (كود ${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = tempFile.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0 && onProgress != null) {
        onProgress(received / total);
      }
    }
    await sink.close();

    // نعيد التسمية فقط بعد اكتمال التحميل بالكامل، حتى لا يبقى ملف ناقص
    await tempFile.rename(file.path);
  }

  Future<void> deleteDownload(int surahNumber) async {
    final file = await _localFile(surahNumber);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// يجهّز المشغل لسورة معينة: من الملف المحلي إن وجد، وإلا يبث من الإنترنت
  Future<void> loadSurah(int surahNumber) async {
    final file = await _localFile(surahNumber);
    if (await file.exists()) {
      await player.setFilePath(file.path);
    } else {
      await player.setUrl(remoteUrl(surahNumber));
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> dispose() => player.dispose();
}
