import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router.dart';
import '../../../core/stroll/script_templates.dart';
import '../../../core/stroll/stroll_controller.dart';
import '../../../core/stroll/stroll_models.dart';
import '../../../core/theme.dart';

/// Full-screen “we're generating your post” beat between capture and the
/// post editor. Calls POST /api/render (or a contract-shaped mock).
class GeneratingPostScreen extends StatefulWidget {
  const GeneratingPostScreen({super.key, required this.businessId});

  final int businessId;

  @override
  State<GeneratingPostScreen> createState() => _GeneratingPostScreenState();
}

class _GeneratingPostScreenState extends State<GeneratingPostScreen>
    with TickerProviderStateMixin {
  static const _messages = [
    'Framing your shots…',
    'Writing a caption worth posting…',
    'Animating stills…',
    'Recording the voiceover…',
    'Cutting it together…',
    'Almost ready…',
  ];

  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _progress;
  late final AnimationController _message;

  int _messageIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90000),
    )..forward();

    _message = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _cycleMessages();
    _renderAndFinish();
  }

  Future<void> _cycleMessages() async {
    for (var i = 1; i < _messages.length; i++) {
      await Future<void>.delayed(const Duration(seconds: 12));
      if (!mounted || _error != null) return;
      await _message.reverse();
      if (!mounted) return;
      setState(() => _messageIndex = i);
      await _message.forward();
    }
  }

  Future<void> _renderAndFinish() async {
    final controller = StrollScope.of(context, listen: false);
    final stroll = controller.state;
    final draft = stroll.draftFor(widget.businessId);
    final b = businessById(widget.businessId);
    final script = scriptForStroll(stroll);
    final step = script.firstWhere(
      (s) => s.businessId == widget.businessId,
      orElse: () => script.isNotEmpty
          ? script.first
          : ScriptStep(
              businessId: widget.businessId,
              sceneTitle: 'SCENE',
              direction: '',
              line: draftCaption(b),
              actions: const [],
            ),
    );

    try {
      final outcome = await apiClient.render(
        business: b,
        draft: draft,
        step: step,
      );
      if (!mounted) return;
      final pkg = outcome.package;
      controller.updateDraft(
        widget.businessId,
        outcome.draft.copyWith(
          renderedVideoUrl: pkg.absoluteVideoUrl,
          renderedCaption: pkg.caption,
          renderedHashtags: pkg.hashtags,
          renderedScript: pkg.script,
        ),
      );
      context.pushReplacement(AppRoutes.postPath(widget.businessId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not render — tap to retry');
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _progress.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1),
            end: Alignment(0.9, 1.1),
            colors: [
              StrollingColors.primary,
              StrollingColors.primaryMid,
              StrollingColors.primarySoft,
            ],
            stops: [0.05, 0.55, 0.95],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: Listenable.merge([_spin, _pulse]),
                  builder: (context, child) {
                    final pulse = 0.88 + (_pulse.value * 0.12);
                    return Transform.scale(
                      scale: pulse,
                      child: SizedBox(
                        width: 168,
                        height: 168,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final ring in const [1.0, 0.72, 0.48])
                              Transform.rotate(
                                angle: _spin.value *
                                    math.pi *
                                    2 *
                                    (ring == 1.0 ? 1 : -0.6),
                                child: CustomPaint(
                                  size: Size(168 * ring, 168 * ring),
                                  painter: _OrbitPainter(
                                    progress: _spin.value,
                                    opacity: 0.18 + (1 - ring) * 0.2,
                                  ),
                                ),
                              ),
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                'assets/images/sparkle_icon.svg',
                                width: 36,
                                height: 36,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'Generating your post',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.6,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                if (_error != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _error = null);
                      _renderAndFinish();
                    },
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        height: 1.4,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  FadeTransition(
                    opacity: _message,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _message,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: Text(
                        _messages[_messageIndex],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final value = Curves.easeInOutCubic.transform(
                      _progress.value.clamp(0.0, 1.0),
                    );
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${(value * 100).round()}%',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: opacity);

    canvas.drawCircle(center, radius, ring);

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: opacity + 0.35);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * math.pi * 2,
      math.pi * 0.55,
      false,
      sweep,
    );

    final dotAngle = progress * math.pi * 2 + math.pi * 0.55;
    final dot = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(
      dot,
      3.2,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
