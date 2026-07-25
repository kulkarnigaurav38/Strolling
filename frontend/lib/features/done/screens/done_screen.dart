import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/copy.dart';
import '../../../core/models.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/local_image.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_button.dart';

class DoneScreen extends ConsumerStatefulWidget {
  const DoneScreen({super.key});

  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen> {
  VideoPlayerController? _video;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = ref.read(sessionProvider).videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _videoFailed = true);
      return;
    }
    final controller = url.startsWith('assets/')
        ? VideoPlayerController.asset(url)
        : VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      // Never hang on a spinner — if init stalls (a known video_player web
      // quirk), fall back to the captured-photo slideshow.
      await controller.initialize().timeout(const Duration(seconds: 8));
      await controller.setLooping(true);
      await controller.setVolume(0); // muted → autoplay is allowed on web
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _video = controller);
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  String _captionBlock(ShootSession s) => [
        s.caption ?? '',
        (s.hashtags ?? []).join(' '),
      ].where((e) => e.isNotEmpty).join('\n\n');

  Future<void> _copy(ShootSession s) async {
    await Clipboard.setData(ClipboardData(text: _captionBlock(s)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caption copied ✓'),
          duration: Duration(milliseconds: 1400),
        ),
      );
    }
  }

  void _openPost() {
    // TODO(COMMIT-5): launch the real Short URL. Mocked as a confirmation.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening the published Short… (mock)'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final photos = session.captures
        .where((c) => c.mediaUrl.isNotEmpty && c.kind == TaskType.photo)
        .toList();

    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const Center(child: Pill(label: '🎉 Published')),
            const SizedBox(height: 12),
            const Text(
              'Your film is live.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // Player, or a photo slideshow if the mock video is missing/blocked.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                color: Colors.black,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _buildMedia(photos),
              ),
            ),
            const SizedBox(height: 20),

            // Caption + hashtags with copy.
            _CaptionCard(
              caption: session.caption ?? '',
              hashtags: session.hashtags ?? const [],
              onCopy: () => _copy(session),
            ),
            const SizedBox(height: 12),

            if (session.postUrl != null)
              GhostButton(
                label: '🎉 View the published Short ↗',
                underline: true,
                onPressed: _openPost,
              ),
            const SizedBox(height: 8),

            // The payoff — the whole reason they walked in.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.amber.withValues(alpha: 0.16),
                    AppColors.orange.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border:
                    Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
              ),
              child: const Text(
                Copy.payoff,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            GhostButton(
              label: 'Start over',
              onPressed: () => ref.read(sessionProvider.notifier).reset(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(List<Capture> photos) {
    if (_video != null && !_videoFailed) {
      return GestureDetector(
        onTap: () {
          final v = _video!;
          if (v.value.isPlaying) {
            v.pause();
          } else {
            v.play();
          }
          setState(() {});
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: _video!.value.aspectRatio == 0
                ? 9 / 16
                : _video!.value.aspectRatio,
            child: VideoPlayer(_video!),
          ),
        ),
      );
    }
    if (!_videoFailed) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }
    return _Slideshow(photos: photos);
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.caption,
    required this.hashtags,
    required this.onCopy,
  });

  final String caption;
  final List<String> hashtags;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.panel, AppColors.panel2],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'CAPTION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(caption, style: const TextStyle(fontSize: 15, height: 1.45)),
          const SizedBox(height: 12),
          Text(
            hashtags.join(' '),
            style: const TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Slideshow extends StatefulWidget {
  const _Slideshow({required this.photos});

  final List<Capture> photos;

  @override
  State<_Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<_Slideshow> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.photos.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
        if (!mounted) return;
        setState(() => _i = (_i + 1) % widget.photos.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: AppColors.panel,
          child: Center(
            child: Text(
              'Your captured shots will play here 🎞️',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
    }
    final photo = widget.photos[_i];
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: localImageProvider(photo.mediaUrl),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppColors.panel,
              child: Center(child: Text('📸', style: TextStyle(fontSize: 34))),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (n) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: n == _i
                        ? AppColors.amber
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
