import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api.dart';
import '../widgets/ayah_card.dart';
import '../widgets/audio_player_bar.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;
  const SurahScreen({super.key, required this.surah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final QuranApiService _api = QuranApiService();
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ayahs = await _api.getSurahAyahs(
        widget.surah.number,
        withTranslation: _showTranslation,
      );
      setState(() {
        _ayahs = ayahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.name),
        actions: [
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate : Icons.translate_outlined,
            ),
            tooltip: 'إظهار/إخفاء الترجمة',
            onPressed: () {
              setState(() => _showTranslation = !_showTranslation);
              _load();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        AudioPlayerBar(surahNumber: widget.surah.number),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _ayahs.length,
            itemBuilder: (context, index) => AyahCard(ayah: _ayahs[index]),
          ),
        ),
      ],
    );
  }
}
