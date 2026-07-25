import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/copy.dart';
import '../../../core/models.dart';
import '../../../core/theme.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/local_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/director_widget.dart';

class InterviewPanel extends ConsumerStatefulWidget {
  const InterviewPanel({super.key});

  @override
  ConsumerState<InterviewPanel> createState() => _InterviewPanelState();
}

class _InterviewPanelState extends ConsumerState<InterviewPanel> {
  final _controller = TextEditingController();
  bool _edited = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _oneSentence(String text, String fallback) {
    final t = text.trim();
    if (t.isEmpty) return fallback;
    final match = RegExp(r'^.*?[.!?]').firstMatch(t);
    final first = match?.group(0) ?? t;
    return first.length > 4 ? first : t;
  }

  void _done(Task task) {
    final text = _controller.text.trim().isEmpty
        ? task.suggestedLine
        : _controller.text.trim();
    ref.read(sessionProvider.notifier).addReview(
          Review(
            taskId: task.id,
            transcript: text,
            // TODO(COMMIT-2): agent returns a real summary; mock takes 1st sentence.
            summary: _oneSentence(text, task.suggestedLine),
          ),
        );
    // Router redirects to /shoot (next) or /render (after the last shot).
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final task = session.currentTask;
    if (task == null) {
      return const AppScaffold(child: SizedBox.shrink());
    }
    Capture? capture;
    for (final c in session.captures) {
      if (c.taskId == task.id) {
        capture = c;
        break;
      }
    }

    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shot ${session.currentTaskIndex + 1} · ${task.title}',
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (capture != null && capture.mediaUrl.isNotEmpty)
                    _CapturePreview(capture: capture),
                  const SizedBox(height: 16),
                  DirectorWidget(
                    task: task,
                    onTranscript: (t) {
                      if (!_edited && mounted) {
                        _controller.text = t;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OR TYPE YOUR TAKE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => _edited = true,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 15, height: 1.3),
                    decoration: const InputDecoration(
                      hintText: Copy.interviewHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Done talking →', onPressed: () => _done(task)),
        ],
      ),
    );
  }
}

class _CapturePreview extends StatelessWidget {
  const _CapturePreview({required this.capture});

  final Capture capture;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: capture.kind == TaskType.clip
            ? Container(
                color: AppColors.panel,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎬', style: TextStyle(fontSize: 34)),
                      SizedBox(height: 6),
                      Text('clip captured',
                          style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              )
            : Image(
                image: localImageProvider(capture.mediaUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.panel,
                  child: const Center(
                    child: Text('📸', style: TextStyle(fontSize: 34)),
                  ),
                ),
              ),
      ),
    );
  }
}
