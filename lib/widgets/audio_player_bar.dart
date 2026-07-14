import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';

class AudioPlayerBar extends StatefulWidget {
  final int surahNumber;
  const AudioPlayerBar({super.key, required this.surahNumber});

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  final AudioService _audio = AudioService();

  bool _isLoadingAudio = true;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _errorMessage;

  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoadingAudio = true);
    try {
      _isDownloaded = await _audio.isDownloaded(widget.surahNumber);
      await _audio.loadSurah(widget.surahNumber);
      setState(() => _isLoadingAudio = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر تحميل الصوت، تحقق من الاتصال بالإنترنت';
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_audio.player.playing) {
      await _audio.pause();
    } else {
      await _audio.play();
    }
    setState(() {});
  }

  Future<void> _downloadForOffline() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _errorMessage = null;
    });
    try {
      await _audio.downloadSurah(
        widget.surahNumber,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      // بعد التحميل، أعد تحميل المشغل من الملف المحلي مباشرة
      final wasPlaying = _audio.player.playing;
      final position = _audio.player.position;
      await _audio.loadSurah(widget.surahNumber);
      await _audio.seek(position);
      if (wasPlaying) await _audio.play();

      setState(() {
        _isDownloaded = true;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل التحميل، حاول مرة أخرى';
        _isDownloading = false;
      });
    }
  }

  Future<void> _deleteDownload() async {
    final wasPlaying = _audio.player.playing;
    final position = _audio.player.position;
    await _audio.deleteDownload(widget.surahNumber);
    await _audio.loadSurah(widget.surahNumber);
    await _audio.seek(position);
    if (wasPlaying) await _audio.play();
    setState(() => _isDownloaded = false);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    // ملاحظة: لا نستدعي player.dispose() هنا لأنه Singleton مشترك
    // بين الشاشات، يُغلق فقط عند إغلاق التطبيق بالكامل
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: _isLoadingAudio
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _errorMessage != null
              ? Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    TextButton(onPressed: _init, child: const Text('إعادة')),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        const Text('🎙️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'الشيخ ياسر الدوسري',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildDownloadButton(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<Duration>(
                      stream: _audio.player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration =
                            _audio.player.duration ?? Duration.zero;
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inMilliseconds > 0
                                    ? duration.inMilliseconds.toDouble()
                                    : 1,
                                value: position.inMilliseconds
                                    .clamp(0, duration.inMilliseconds)
                                    .toDouble(),
                                onChanged: (value) {
                                  _audio.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    StreamBuilder<PlayerState>(
                      stream: _audio.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        final processingState =
                            snapshot.data?.processingState;
                        final isBuffering = processingState ==
                                ProcessingState.buffering ||
                            processingState == ProcessingState.loading;

                        return IconButton(
                          iconSize: 46,
                          icon: isBuffering
                              ? const SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  playing
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: scheme.primary,
                                ),
                          onPressed: isBuffering ? null : _togglePlayPause,
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloading) {
      return SizedBox(
        height: 28,
        width: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              value: _downloadProgress > 0 ? _downloadProgress : null,
            ),
          ],
        ),
      );
    }

    if (_isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.download_done, color: Colors.green),
        tooltip: 'محملة - اضغط للحذف',
        onPressed: _deleteDownload,
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_outlined),
      tooltip: 'تحميل للاستماع بدون نت',
      onPressed: _downloadForOffline,
    );
  }
}
