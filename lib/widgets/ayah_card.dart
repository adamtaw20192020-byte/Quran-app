import 'package:flutter/material.dart';
import '../models/ayah.dart';
import '../services/bookmark_service.dart';

class AyahCard extends StatefulWidget {
  final Ayah ayah;
  final bool showSurahName;

  const AyahCard({
    super.key,
    required this.ayah,
    this.showSurahName = false,
  });

  @override
  State<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<AyahCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final result = await _bookmarkService.isBookmarked(widget.ayah);
    if (mounted) setState(() => _isBookmarked = result);
  }

  Future<void> _toggleBookmark() async {
    await _bookmarkService.toggleBookmark(widget.ayah);
    await _checkBookmark();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${widget.ayah.numberInSurah}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                if (widget.showSurahName) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.ayah.surahName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isBookmarked
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.ayah.text,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 22, height: 1.9),
            ),
            if (widget.ayah.translation != null &&
                widget.ayah.translation!.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                widget.ayah.translation!,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
