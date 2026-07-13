import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ayah.dart';

/// يحفظ الآيات المفضلة محلياً على الجهاز (بدون سيرفر)
class BookmarkService {
  static const String _storageKey = 'bookmarked_ayahs';

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<bool> isBookmarked(Ayah ayah) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b['key'] == ayah.bookmarkKey);
  }

  Future<void> toggleBookmark(Ayah ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    final exists = bookmarks.any((b) => b['key'] == ayah.bookmarkKey);
    if (exists) {
      bookmarks.removeWhere((b) => b['key'] == ayah.bookmarkKey);
    } else {
      bookmarks.add({
        'key': ayah.bookmarkKey,
        'surahNumber': ayah.surahNumber,
        'surahName': ayah.surahName,
        'numberInSurah': ayah.numberInSurah,
        'text': ayah.text,
      });
    }

    await prefs.setString(_storageKey, json.encode(bookmarks));
  }

  Future<void> removeBookmark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b['key'] == key);
    await prefs.setString(_storageKey, json.encode(bookmarks));
  }
}
