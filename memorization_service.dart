import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memorization_entry.dart';

/// يحفظ سجلات متابعة الحفظ (الاسم، الحفظ الجديد، المراجعة، التقييم) محلياً
class MemorizationService {
  static const String _storageKey = 'memorization_entries';

  Future<List<MemorizationEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    final entries = list
        .map((e) => MemorizationEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // الأحدث أولاً
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> addEntry(MemorizationEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.add(entry);
    await prefs.setString(
      _storageKey,
      json.encode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.removeWhere((e) => e.id == id);
    await prefs.setString(
      _storageKey,
      json.encode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
