import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/map_business.dart';
import '../../../core/router.dart';
import '../../../core/stroll/script_templates.dart';
import '../../../core/stroll/stroll_controller.dart';
import '../../../core/stroll/stroll_models.dart';
import '../../../core/theme.dart';

/// One scene of the stroll — Figma CursorStutt StepScreen.
class StepScreen extends StatefulWidget {
  const StepScreen({super.key, required this.businessId});

  final int businessId;

  @override
  State<StepScreen> createState() => _StepScreenState();
}

enum _ScriptMode { ai, writeOwn }

class _StepScreenState extends State<StepScreen> {
  late final TextEditingController _noteController;
  Timer? _voiceTimer;
  int _recordingSeconds = 0;
  bool _recording = false;
  _ScriptMode _mode = _ScriptMode.ai;

  @override
  void initState() {
    super.initState();
    final draft =
        StrollScope.of(context, listen: false).state.draftFor(widget.businessId);
    _noteController = TextEditingController(text: draft.note ?? '');
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  StopDraft get _draft =>
      StrollScope.of(context).state.draftFor(widget.businessId);

  void _update(StopDraft next) {
    StrollScope.of(context, listen: false).updateDraft(
      widget.businessId,
      next.copyWith(savedAt: DateTime.now()),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 80,
        ) ??
        await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          imageQuality: 80,
        );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _update(
      _draft.copyWith(
        photoBase64: base64Encode(bytes),
        photoUrl: null,
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.camera) ??
        await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _update(
      _draft.copyWith(
        videoName: file.name,
        videoBytes: bytes,
        videoUrl: null,
      ),
    );
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

  Future<void> _runCapture(CaptureAction kind) async {
    switch (kind) {
      case CaptureAction.photo:
        await _pickPhoto();
      case CaptureAction.video:
        await _pickVideo();
      case CaptureAction.voice:
        _toggleRecording();
      case CaptureAction.text:
        // Focus handled by write-own field; no-op here.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stroll = StrollScope.of(context).state;
    final script = scriptForStroll(stroll);
    // Never throw from build(): an empty stroll (deep link, cleared state,
    // hot restart) used to raise StateError and show Flutter's red screen.
    if (script.isEmpty) return const _NoActiveStroll();
    final step = script.firstWhere(
      (s) => s.businessId == widget.businessId,
      orElse: () => script.first,
    );
    final draft = _draft;
    final b = businessById(step.businessId);
    final stepIndex = stroll.stopIds.indexOf(widget.businessId);
    final total = stroll.stopIds.length;
    final canPost = draft.hasAnyCapture && step.satisfiedBy(draft);

    return Scaffold(
      backgroundColor: StrollingColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _ProgressHeader(
              current: stepIndex + 1,
              total: total,
              onBack: () => context.pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                _StopHero(
                  business: b,
                  stopIndex: stepIndex + 1,
                  total: total,
                ),
                const SizedBox(height: 12),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 12),
                if (_mode == _ScriptMode.ai) ...[
                  if (step.locationTitle != null && step.locationBody != null)
                    _LocationOverview(
                      title: step.locationTitle!,
                      body: step.locationBody!,
                    ),
                  for (final block in step.blocks) ...[
                    if (block.narrative != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          block.narrative!,
                          style: GoogleFonts.nunito(
                            fontSize: 14.1,
                            height: 1.7,
                            fontWeight: FontWeight.w400,
                            color: StrollingColors.ink,
                          ),
                        ),
                      ),
                    if (block.isCapture)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _InlineCaptureCard(
                          block: block,
                          done: draft.has(block.captureKind!),
                          recording: _recording &&
                              block.captureKind == CaptureAction.voice,
                          recordingSeconds: _recordingSeconds,
                          voiceSeconds: draft.voiceSeconds ?? 0,
                          onCapture: () => _runCapture(block.captureKind!),
                          onRedo: () {
                            switch (block.captureKind!) {
                              case CaptureAction.photo:
                                _update(_draft.copyWith(clearPhoto: true));
                              case CaptureAction.video:
                                _update(_draft.copyWith(clearVideo: true));
                              case CaptureAction.voice:
                                _update(_draft.copyWith(clearVoice: true));
                              case CaptureAction.text:
                                _update(_draft.copyWith(clearNote: true));
                            }
                          },
                        ),
                      ),
                  ],
                ] else ...[
                  const SizedBox(height: 4),
                  _WriteOwnPanel(
                    controller: _noteController,
                    onChanged: (text) => _update(_draft.copyWith(note: text)),
                    onPickPhoto: _pickPhoto,
                    onPickVideo: _pickVideo,
                    onToggleVoice: _toggleRecording,
                    recording: _recording,
                    voiceSeconds:
                        _recording ? _recordingSeconds : (draft.voiceSeconds ?? 0),
                    draft: draft,
                  ),
                ],
                const SizedBox(height: 16),
                _CapturesSummary(draft: draft),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _BottomActions(
            canPost: canPost,
            onPrimary: canPost
                ? () => context.push(AppRoutes.generatingPostPath(b.id))
                : null,
            onSave: () => context.pop(),
            onBackToStroll: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.onBack,
  });

  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: StrollingColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4DA),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: i < current - 1
                            ? 1
                            : (i == current - 1 ? 1 : 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: StrollingColors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$current/$total',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: StrollingColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopHero extends StatelessWidget {
  const _StopHero({
    required this.business,
    required this.stopIndex,
    required this.total,
  });

  final MapBusiness business;
  final int stopIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final heroAsset = business.id == 1
        ? 'assets/images/scene/brot_roesterei.jpg'
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 148,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (heroAsset != null)
              Image.asset(heroAsset, fit: BoxFit.cover)
            else
              Image.network(
                business.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1B1928),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.55, 1],
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1B1928).withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            // Soft dark wash so text stays readable even on light photos.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B1928).withValues(alpha: 0.15),
                    const Color(0xFF1B1928).withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'STOP $stopIndex OF $total',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.7,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        Text(
                          business.name,
                          style: GoogleFonts.fraunces(
                            fontWeight: FontWeight.w700,
                            fontSize: 19.2,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (business.hasPerk && business.perkVal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5A623)
                                .withValues(alpha: 0.38),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            business.categoryIcon,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            business.perkVal!,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 10.4,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _ScriptMode mode;
  final ValueChanged<_ScriptMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x121B1928)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'AI script',
              selected: mode == _ScriptMode.ai,
              icon: SvgPicture.asset(
                'assets/images/sparkle_icon.svg',
                width: 13,
                height: 13,
                colorFilter: ColorFilter.mode(
                  mode == _ScriptMode.ai
                      ? Colors.white
                      : StrollingColors.muted,
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => onChanged(_ScriptMode.ai),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeChip(
              label: 'Write my own',
              selected: mode == _ScriptMode.writeOwn,
              icon: Icon(
                CupertinoIcons.pencil,
                size: 13,
                color: mode == _ScriptMode.writeOwn
                    ? Colors.white
                    : StrollingColors.muted,
              ),
              onTap: () => onChanged(_ScriptMode.writeOwn),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? StrollingColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: StrollingColors.primary.withValues(alpha: 0.21),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: selected ? Colors.white : StrollingColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationOverview extends StatelessWidget {
  const _LocationOverview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1928), Color(0xFF2D2A3E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/pin_icon.svg',
                width: 13,
                height: 13,
                colorFilter: const ColorFilter.mode(
                  StrollingColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LOCATION OVERVIEW',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 10.4,
                  letterSpacing: 0.62,
                  color: StrollingColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              fontSize: 18.4,
              height: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 13.1,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCaptureCard extends StatelessWidget {
  const _InlineCaptureCard({
    required this.block,
    required this.done,
    required this.recording,
    required this.recordingSeconds,
    required this.voiceSeconds,
    required this.onCapture,
    required this.onRedo,
  });

  final SceneBlock block;
  final bool done;
  final bool recording;
  final int recordingSeconds;
  final int voiceSeconds;
  final VoidCallback onCapture;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final kind = block.captureKind!;
    final icon = switch (kind) {
      CaptureAction.voice => CupertinoIcons.mic_fill,
      CaptureAction.text => CupertinoIcons.pencil,
      _ => CupertinoIcons.camera_fill,
    };

    String cta = block.ctaLabel;
    if (kind == CaptureAction.voice) {
      if (recording) {
        cta = 'Stop · ${_fmt(recordingSeconds)}';
      } else if (done) {
        cta = 'Recorded · ${_fmt(voiceSeconds)}';
      }
    } else if (done) {
      cta = kind == CaptureAction.video ? 'Clip captured · Redo' : 'Photo captured · Redo';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StrollingColors.primary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? StrollingColors.success.withValues(alpha: 0.45)
              : StrollingColors.primary.withValues(alpha: 0.31),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: StrollingColors.primary.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done ? StrollingColors.success : StrollingColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? CupertinoIcons.checkmark : icon,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.captureTitle!,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.2,
                    letterSpacing: 0.45,
                    color: done
                        ? StrollingColors.successDeep
                        : StrollingColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.capturePrompt!,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 12.5,
              height: 1.55,
              color: StrollingColors.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: done && !recording && kind != CaptureAction.voice
                ? onRedo
                : onCapture,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: StrollingColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: StrollingColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    recording
                        ? Icons.stop_rounded
                        : (done ? Icons.refresh_rounded : icon),
                    size: 15,
                    color: StrollingColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cta,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: StrollingColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class _WriteOwnPanel extends StatelessWidget {
  const _WriteOwnPanel({
    required this.controller,
    required this.onChanged,
    required this.onPickPhoto,
    required this.onPickVideo,
    required this.onToggleVoice,
    required this.recording,
    required this.voiceSeconds,
    required this.draft,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onToggleVoice;
  final bool recording;
  final int voiceSeconds;
  final StopDraft draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your take',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: StrollingColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Write what you want to capture here…',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x121B1928)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x121B1928)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InlineCaptureCard(
          block: const SceneBlock.capture(
            captureTitle: 'CAPTURE — PHOTO',
            capturePrompt: 'Shoot whatever feels right for this stop.',
            captureKind: CaptureAction.photo,
          ),
          done: draft.hasPhoto,
          recording: false,
          recordingSeconds: 0,
          voiceSeconds: 0,
          onCapture: onPickPhoto,
          onRedo: onPickPhoto,
        ),
        const SizedBox(height: 12),
        _InlineCaptureCard(
          block: const SceneBlock.capture(
            captureTitle: 'CAPTURE — VIDEO',
            capturePrompt: 'A short clip — your call on length and angle.',
            captureKind: CaptureAction.video,
          ),
          done: draft.hasVideo,
          recording: false,
          recordingSeconds: 0,
          voiceSeconds: 0,
          onCapture: onPickVideo,
          onRedo: onPickVideo,
        ),
        const SizedBox(height: 12),
        _InlineCaptureCard(
          block: const SceneBlock.capture(
            captureTitle: 'CAPTURE — VOICE',
            capturePrompt: 'Talk through your own script.',
            captureKind: CaptureAction.voice,
          ),
          done: draft.hasVoice && !recording,
          recording: recording,
          recordingSeconds: voiceSeconds,
          voiceSeconds: voiceSeconds,
          onCapture: onToggleVoice,
          onRedo: onToggleVoice,
        ),
      ],
    );
  }
}

class _CapturesSummary extends StatelessWidget {
  const _CapturesSummary({required this.draft});

  final StopDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x121B1928)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAPTURES FOR THIS STOP',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 11.2,
              letterSpacing: 0.56,
              color: StrollingColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  icon: CupertinoIcons.camera_fill,
                  label: 'Photo / Video',
                  done: draft.hasPhoto || draft.hasVideo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  icon: CupertinoIcons.mic_fill,
                  label: 'Voice',
                  done: draft.hasVoice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  icon: CupertinoIcons.pencil,
                  label: 'Notes',
                  done: draft.hasNote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: done
            ? StrollingColors.successBg
            : const Color(0xFFF2EFE8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? StrollingColors.success.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Icon(
            done ? CupertinoIcons.checkmark_circle_fill : icon,
            size: 14,
            color: done ? StrollingColors.successDeep : const Color(0xFFB0ACBC),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 9.9,
              color: done ? StrollingColors.successDeep : const Color(0xFFB0ACBC),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.canPost,
    required this.onPrimary,
    required this.onSave,
    required this.onBackToStroll,
  });

  final bool canPost;
  final VoidCallback? onPrimary;
  final VoidCallback onSave;
  final VoidCallback onBackToStroll;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: StrollingColors.background,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPrimary,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canPost
                    ? StrollingColors.primaryDeep
                    : const Color(0xFFF2EFE8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                canPost ? 'Build post →' : 'Capture something first',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.2,
                  color: canPost ? Colors.white : StrollingColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  onTap: onSave,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.bookmark,
                        size: 14,
                        color: StrollingColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Save & come back',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: StrollingColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(
                  onTap: onBackToStroll,
                  child: Text(
                    '← Back to stroll',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: StrollingColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFE8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

/// Shown when the step screen is opened without an active stroll instead of
/// throwing out of build().
class _NoActiveStroll extends StatelessWidget {
  const _NoActiveStroll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StrollingColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined,
                    size: 46, color: StrollingColors.muted),
                const SizedBox(height: 14),
                Text(
                  'No active stroll',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: StrollingColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a couple of stops on the map to start one.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: StrollingColors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.creatorHome),
                  style: FilledButton.styleFrom(
                    backgroundColor: StrollingColors.primary,
                  ),
                  child: Text(
                    'Open the map',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
