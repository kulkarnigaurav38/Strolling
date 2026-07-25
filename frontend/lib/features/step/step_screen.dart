import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/copy.dart';
import '../../core/models.dart';
import '../../core/script_templates.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// One scene of the stroll: the themed script card on top (with the action
/// chips the script calls for), then the three independent capture cards.
class StepScreen extends ConsumerStatefulWidget {
  final String businessId;
  const StepScreen({super.key, required this.businessId});

  @override
  ConsumerState<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends ConsumerState<StepScreen> {
  final _mediaKey = GlobalKey();
  final _voiceKey = GlobalKey();
  final _noteKey = GlobalKey();

  late final TextEditingController _noteController;

  // Mock voice recorder.
  Timer? _voiceTimer;
  int _recordingSeconds = 0;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(strollProvider).draftFor(widget.businessId);
    _noteController = TextEditingController(text: draft.note ?? '');
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  StopDraft get _draft =>
      ref.watch(strollProvider).draftFor(widget.businessId);

  void _update(StopDraft next) => ref
      .read(strollProvider.notifier)
      .updateDraft(widget.businessId, next.copyWith(savedAt: DateTime.now()));

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
    // Camera falls back to gallery/file dialog where unavailable (web/desktop).
    final chosen = file ??
        await picker.pickImage(
            source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (chosen == null) return;
    final bytes = await chosen.readAsBytes();
    _update(_draft.copyWith(photoBase64: base64Encode(bytes)));
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.camera) ??
        await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    _update(_draft.copyWith(videoName: file.name));
  }

  void _toggleRecording() {
    if (_recording) {
      _voiceTimer?.cancel();
      setState(() => _recording = false);
      _update(_draft.copyWith(voiceSeconds: _recordingSeconds));
    } else {
      setState(() {
        _recording = true;
        _recordingSeconds = 0;
      });
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordingSeconds++);
      });
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.1,
        curve: Curves.easeOutCubic);
  }

  GlobalKey _keyFor(CaptureAction a) => switch (a) {
        CaptureAction.photo || CaptureAction.video => _mediaKey,
        CaptureAction.voice => _voiceKey,
        CaptureAction.text => _noteKey,
      };

  @override
  Widget build(BuildContext context) {
    final stroll = ref.watch(strollProvider);
    final script = ref.watch(strollScriptProvider);
    final step = script.firstWhere(
      (s) => s.businessId == widget.businessId,
      orElse: () => script.isEmpty
          ? throw StateError('no active stroll')
          : script.first,
    );
    final template = templateById(stroll.templateId);
    final draft = _draft;
    final b = businessById(step.businessId);

    final stepIndex = stroll.stopIds.indexOf(widget.businessId);
    final progress = (stepIndex + 1) / stroll.stopIds.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(b.name,
                style: titleStyle(size: 18)
                    .copyWith(fontWeight: FontWeight.w700)),
            Text('Stop ${stepIndex + 1} of ${stroll.stopIds.length}',
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(template.color),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
        children: [
          _ScriptCard(
            step: step,
            template: template,
            draft: draft,
            onActionTap: (a) => _scrollTo(_keyFor(a.kind)),
          ),
          const SizedBox(height: 14),
          _MediaCard(
            key: _mediaKey,
            draft: draft,
            onPickPhoto: _pickPhoto,
            onPickVideo: _pickVideo,
            onRedoPhoto: () => _update(_draft.copyWith(clearPhoto: true)),
            onRedoVideo: () => _update(_draft.copyWith(clearVideo: true)),
          ),
          const SizedBox(height: 12),
          _VoiceCard(
            key: _voiceKey,
            draft: draft,
            recording: _recording,
            seconds: _recording ? _recordingSeconds : (draft.voiceSeconds ?? 0),
            onToggle: _toggleRecording,
            onRedo: () => _update(_draft.copyWith(clearVoice: true)),
          ),
          const SizedBox(height: 12),
          _NoteCard(
            key: _noteKey,
            draft: draft,
            controller: _noteController,
            onChanged: (text) => _update(_draft.copyWith(note: text)),
          ),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(Copy.saveAndComeBack,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: draft.hasAnyCapture && step.satisfiedBy(draft)
                    ? () => context.push('/post/${b.id}')
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 54,
                  decoration: BoxDecoration(
                    color: draft.hasAnyCapture && step.satisfiedBy(draft)
                        ? AppColors.coral
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Center(
                    child: Text(
                      Copy.buildPost,
                      style: TextStyle(
                        color: draft.hasAnyCapture && step.satisfiedBy(draft)
                            ? Colors.white
                            : AppColors.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The themed script: scene title, direction, the line, perk deliverable,
/// and the action chips — "which capture to open".
class _ScriptCard extends StatelessWidget {
  final ScriptStep step;
  final ScriptTemplate template;
  final StopDraft draft;
  final ValueChanged<ScriptAction> onActionTap;

  const _ScriptCard({
    required this.step,
    required this.template,
    required this.draft,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 18,
                decoration: BoxDecoration(
                  color: template.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(template.icon, size: 15, color: template.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  step.sceneTitle,
                  style: TextStyle(
                    color: template.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.direction,
              style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('“${step.line}”',
                style: titleStyle(size: 15.5)
                    .copyWith(fontWeight: FontWeight.w600, height: 1.4)),
          ),
          if (step.perkCallout != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.card_giftcard,
                    size: 16, color: AppColors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.perkCallout!,
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in step.actions)
                _ActionChip(
                  action: a,
                  done: draft.has(a.kind),
                  color: template.color,
                  onTap: () => onActionTap(a),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final ScriptAction action;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.action,
    required this.done,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: done ? AppColors.green.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: done
                ? AppColors.green
                : (action.required ? color : AppColors.border),
            width: action.required && !done ? 2 : 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? CupertinoIcons.checkmark_circle_fill : action.kind.icon,
              size: 15,
              color: done
                  ? AppColors.green
                  : (action.required ? color : AppColors.muted),
            ),
            const SizedBox(width: 6),
            Text(
              action.required
                  ? '${action.kind.label} · required'
                  : action.kind.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: done ? AppColors.green : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capture cards
// ---------------------------------------------------------------------------

class _CaptureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onRedo;
  final Widget child;

  const _CaptureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.child,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: done ? AppColors.green : AppColors.border,
            width: done ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              if (done) ...[
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 22),
                if (onRedo != null)
                  TextButton(
                    onPressed: onRedo,
                    child: const Text('Redo',
                        style: TextStyle(color: AppColors.muted)),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final StopDraft draft;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onRedoPhoto;
  final VoidCallback onRedoVideo;

  const _MediaCard({
    super.key,
    required this.draft,
    required this.onPickPhoto,
    required this.onPickVideo,
    required this.onRedoPhoto,
    required this.onRedoVideo,
  });

  @override
  Widget build(BuildContext context) {
    final done = draft.hasPhoto || draft.hasVideo;
    return _CaptureCard(
      icon: CupertinoIcons.camera_fill,
      title: 'Photo / Video',
      subtitle: 'Shoot what the scene calls for',
      done: done,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (draft.hasPhoto)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(draft.photoBase64!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: onRedoPhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Text('Redo',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          if (draft.hasVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: AppColors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Clip captured · ${draft.videoName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: onRedoVideo,
                    child: const Text('Redo',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (!draft.hasPhoto || !draft.hasVideo)
            Padding(
              padding: EdgeInsets.only(top: done ? 10 : 0),
              child: Row(
                children: [
                  if (!draft.hasPhoto)
                    Expanded(
                      child: _MediaButton(
                          label: 'Take photo',
                          icon: Icons.photo_camera_outlined,
                          onTap: onPickPhoto),
                    ),
                  if (!draft.hasPhoto && !draft.hasVideo)
                    const SizedBox(width: 10),
                  if (!draft.hasVideo)
                    Expanded(
                      child: _MediaButton(
                          label: 'Record clip',
                          icon: Icons.videocam_outlined,
                          onTap: onPickVideo),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MediaButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.coral),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  final StopDraft draft;
  final bool recording;
  final int seconds;
  final VoidCallback onToggle;
  final VoidCallback onRedo;

  const _VoiceCard({
    super.key,
    required this.draft,
    required this.recording,
    required this.seconds,
    required this.onToggle,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return _CaptureCard(
      icon: CupertinoIcons.mic_fill,
      title: 'Voice note',
      subtitle: 'Say the line, or your own take',
      done: draft.hasVoice && !recording,
      onRedo: draft.hasVoice && !recording ? onRedo : null,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: recording ? AppColors.coral : AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(recording ? Icons.stop : Icons.mic,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: recording || draft.hasVoice
                ? Row(
                    children: [
                      Expanded(child: _Waveform(active: recording)),
                      const SizedBox(width: 10),
                      Text(
                        _fmt(seconds),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  )
                : const Text('Tap to record',
                    style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _Waveform extends StatefulWidget {
  final bool active;
  const _Waveform({required this.active});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _bars = [0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 1.0, 0.5, 0.7, 0.35, 0.85, 0.55, 0.75];

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Waveform old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.active) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _bars.length; i++)
            Container(
              width: 4,
              height: 30 *
                  _bars[i] *
                  (widget.active
                      ? (0.55 + 0.45 * ((_c.value + i / _bars.length) % 1))
                      : 1),
              decoration: BoxDecoration(
                color: widget.active ? AppColors.coral : AppColors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StopDraft draft;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NoteCard({
    super.key,
    required this.draft,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CaptureCard(
      icon: CupertinoIcons.pencil,
      title: 'Write a note',
      subtitle: 'A caption seed or observation',
      done: draft.hasNote,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Write a note…',
        ),
      ),
    );
  }
}
