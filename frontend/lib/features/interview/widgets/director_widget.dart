import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/theme.dart';

/// Mock stand-in for der Regisseur. It "greets" the shot and types out a short,
/// believable exchange so the interview beat feels alive with zero services.
/// The creator line it lands on becomes the suggested transcript.
///
/// TODO(COMMIT-2): replace with the ElevenLabs conversational WebSocket
/// (web_socket_channel) + client tools; WebView of the React widget as fallback.
class DirectorWidget extends StatefulWidget {
  const DirectorWidget({
    super.key,
    required this.task,
    required this.onTranscript,
  });

  final Task task;
  final ValueChanged<String> onTranscript;

  @override
  State<DirectorWidget> createState() => _DirectorWidgetState();
}

class _DirectorWidgetState extends State<DirectorWidget> {
  static const _mockAnswers = <int, String>{
    1: "First thing you notice is how unassuming the door is for what's inside.",
    2: 'Every table is a different team, totally locked in — the focus is contagious.',
    3: 'Watching someone pair with Cursor live, the code just pours out. Wild.',
    4: 'Honestly the coffee run is where half the ideas actually happen.',
    5: 'The city view from up here makes the whole day feel a little cinematic.',
  };

  late List<_Line> _script;
  List<String> _shown = ['', ''];
  int _line = 0;
  int _char = 0;
  Timer? _timer;

  String get _answer =>
      _mockAnswers[widget.task.order] ?? widget.task.suggestedLine;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant DirectorWidget old) {
    super.didUpdateWidget(old);
    if (old.task.id != widget.task.id) _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    final announce = widget.task.title.replaceFirst(RegExp(r'^\S+\s'), '');
    _script = [
      _Line(
        Speaker.director,
        'Ja, wunderbar — ${announce.toLowerCase()}. When you\'re ready, just talk. What did you make of it?',
      ),
      _Line(Speaker.you, _answer),
    ];
    _shown = ['', ''];
    _line = 0;
    _char = 0;
    _timer = Timer(const Duration(milliseconds: 350), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_line >= _script.length) {
      widget.onTranscript(_answer);
      return;
    }
    final full = _script[_line].text;
    _char++;
    setState(() => _shown[_line] = full.substring(0, _char));
    if (_char >= full.length) {
      _line++;
      _char = 0;
      _timer = Timer(const Duration(milliseconds: 420), _tick);
    } else {
      _timer = Timer(const Duration(milliseconds: 22), _tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.amberGradient,
                ),
                child: const Center(
                  child: Text('🎙️', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('der Regisseur',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('listening… (mock)',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Row(
                children: const [
                  _LiveDot(),
                  SizedBox(width: 6),
                  Text('live',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _script.length; i++)
            if (_shown[i].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Bubble(line: _script[i], text: _shown[i]),
              ),
        ],
      ),
    );
  }
}

enum Speaker { director, you }

class _Line {
  final Speaker who;
  final String text;
  const _Line(this.who, this.text);
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, required this.text});

  final _Line line;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isYou = line.who == Speaker.you;
    return Align(
      alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isYou ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isYou ? 'YOU' : 'REGISSEUR',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isYou
                    ? AppColors.amber.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
