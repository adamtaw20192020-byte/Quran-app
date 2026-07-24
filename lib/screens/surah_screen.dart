import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/audio_player_bar.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;
  const SurahScreen({super.key, required this.surah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final QuranApiService _api = QuranApiService();
  final BookmarkService _bookmarkService = BookmarkService();
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showTranslation = true;
  Set<int> _bookmarkedNumbers = {};

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
      final bookmarked = <int>{};
      for (final a in ayahs) {
        if (await _bookmarkService.isBookmarked(a)) {
          bookmarked.add(a.numberInSurah);
        }
      }
      setState(() {
        _ayahs = ayahs;
        _bookmarkedNumbers = bookmarked;
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
              FilledButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        AudioPlayerBar(surahNumber: widget.surah.number),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(
                  children: _ayahs.expand((ayah) {
                    final isBookmarked =
                        _bookmarkedNumbers.contains(ayah.numberInSurah);
                    return [
                      TextSpan(
                        text: '${ayah.text} ',
                        style: const TextStyle(fontSize: 22, height: 1.9),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () async {
                            await _bookmarkService.toggleBookmark(ayah);
                            setState(() {
                              if (isBookmarked) {
                                _bookmarkedNumbers.remove(ayah.numberInSurah);
                              } else {
                                _bookmarkedNumbers.add(ayah.numberInSurah);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isBookmarked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                            ),
                            child: Text(
                              '${ayah.numberInSurah}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isBookmarked ? Colors.white : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showTranslation &&
                          ayah.translation != null &&
                          ayah.translation!.isNotEmpty)
                        TextSpan(
                          text: '\n${ayah.translation}\n\n',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        const TextSpan(text: '  '),
                    ];
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}