import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_api.dart';

/// كاش بسيط بالذاكرة حتى لا نطلب قائمة السور من الإنترنت في كل مرة
/// يفتح فيها المستخدم نافذة الاختيار خلال نفس جلسة استخدام التطبيق
List<Surah>? _cachedSurahs;

/// يفتح نافذة لاختيار سورة بسرعة، مع خيار "السورة كاملة" أو تحديد نطاق آيات
/// يرجع نص جاهز للإدراج مثل: "سورة البقرة كاملة" أو "سورة البقرة من آية 1 إلى 20"
/// يرجع null إذا ألغى المستخدم العملية
Future<String?> showSurahPickerDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _SurahPickerSheet(),
  );
}

class _SurahPickerSheet extends StatefulWidget {
  const _SurahPickerSheet();

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  final QuranApiService _api = QuranApiService();

  List<Surah> _allSurahs = [];
  List<Surah> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;

  // بعد اختيار سورة، ننتقل لخطوة تحديد "كاملة" أو نطاق
  Surah? _selectedSurah;
  bool _isWholeSurah = true;
  final _fromController = TextEditingController(text: '1');
  final _toController = TextEditingController();
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_cachedSurahs != null) {
      setState(() {
        _allSurahs = _cachedSurahs!;
        _filtered = _cachedSurahs!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final surahs = await _api.getAllSurahs();
      _cachedSurahs = surahs;
      setState(() {
        _allSurahs = surahs;
        _filtered = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر تحميل قائمة السور، تحقق من الاتصال';
        _isLoading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.trim().isEmpty
          ? _allSurahs
          : _allSurahs.where((s) => s.name.contains(query)).toList();
    });
  }

  void _selectSurah(Surah surah) {
    setState(() {
      _selectedSurah = surah;
      _isWholeSurah = true;
      _fromController.text = '1';
      _toController.text = surah.numberOfAyahs.toString();
      _rangeError = null;
    });
  }

  void _confirm() {
    final surah = _selectedSurah!;
    if (_isWholeSurah) {
      Navigator.pop(context, 'سورة ${surah.name} كاملة');
      return;
    }

    final from = int.tryParse(_fromController.text.trim());
    final to = int.tryParse(_toController.text.trim());

    if (from == null || to == null || from < 1 || to > surah.numberOfAyahs || from > to) {
      setState(() {
        _rangeError = 'أدخل نطاق صحيح بين 1 و ${surah.numberOfAyahs}';
      });
      return;
    }

    Navigator.pop(context, 'سورة ${surah.name} من آية $from إلى $to');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: _selectedSurah == null ? _buildSurahList() : _buildRangeStep(),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر السورة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: _filter,
          decoration: InputDecoration(
            hintText: 'ابحث باسم السورة...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildListBody()),
      ],
    );
  }

  Widget _buildListBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final surah = _filtered[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${surah.number}')),
          title: Text(surah.name),
          subtitle: Text('${surah.numberOfAyahs} آية'),
          onTap: () => _selectSurah(surah),
        );
      },
    );
  }

  Widget _buildRangeStep() {
    final surah = _selectedSurah!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedSurah = null),
            ),
            Expanded(
              child: Text(
                surah.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 12),
        RadioListTile<bool>(
          title: const Text('السورة كاملة'),
          value: true,
          groupValue: _isWholeSurah,
          onChanged: (value) => setState(() => _isWholeSurah = value!),
        ),
        RadioListTile<bool>(
          title: const Text('تحديد نطاق آيات معيّن'),
          value: false,
          groupValue: _isWholeSurah,
          onChanged: (value) => setState(() => _isWholeSurah = value!),
        ),
        if (!_isWholeSurah) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'من آية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'إلى آية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (_rangeError != null) ...[
            const SizedBox(height: 6),
            Text(_rangeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
        const Spacer(),
        FilledButton(
          onPressed: _confirm,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
