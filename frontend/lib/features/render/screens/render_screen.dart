import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/copy.dart';
import '../../../core/seed.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_scaffold.dart';

class RenderScreen extends ConsumerStatefulWidget {
  const RenderScreen({super.key});

  @override
  ConsumerState<RenderScreen> createState() => _RenderScreenState();
}

class _RenderScreenState extends ConsumerState<RenderScreen> {
  int _stage = 0;
  Timer? _ticker;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        _stage = (_stage + 1).clamp(0, Copy.renderStages.length - 1);
      });
    });
    _run();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    final api = ref.read(apiClientProvider);
    final notifier = ref.read(sessionProvider.notifier);
    final session = ref.read(sessionProvider);
    try {
      final transcript = session.reviews.map((r) => r.transcript).join(' ');
      final render = await api.render(
        captures: session.captures,
        reviews: session.reviews,
        business: kBusiness,
      );
      notifier.setRender(render);
      final publish =
          await api.publish(videoUrl: render.videoUrl, transcript: transcript);
      notifier.setPublish(publish); // → status done → router redirects to /done
    } catch (_) {
      // In mock this never throws; a real pipeline would surface an error here.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.amber),
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  Text('🎬', style: TextStyle(fontSize: 36)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                Copy.renderStages[_stage],
                key: ValueKey(_stage),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'der Regisseur is cutting your film…',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(Copy.renderStages.length, (i) {
                return Container(
                  width: 24,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= _stage ? AppColors.amber : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
