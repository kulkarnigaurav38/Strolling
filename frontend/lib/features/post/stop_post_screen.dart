import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// The per-stop post builder (v5's StopPostScreen): captured media preview,
/// editable AI caption, platform selector, publish. Publishing marks the stop
/// done and earns the perk (pending → approved).
class StopPostScreen extends ConsumerStatefulWidget {
  final String businessId;
  const StopPostScreen({super.key, required this.businessId});

  @override
  ConsumerState<StopPostScreen> createState() => _StopPostScreenState();
}

class _StopPostScreenState extends ConsumerState<StopPostScreen> {
  late final TextEditingController _caption;
  String _platform = 'instagram';
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _caption =
        TextEditingController(text: draftCaption(businessById(widget.businessId)));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    // Mock latency — a later commit posts through the backend.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final stroll = ref.read(strollProvider);
    final draft = stroll.draftFor(widget.businessId);
    ref.read(strollProvider.notifier).updateDraft(
          widget.businessId,
          draft.copyWith(posted: true, postedPlatform: _platform),
        );
    final b = businessById(widget.businessId);
    if (b.hasPerk) {
      ref.read(perksProvider.notifier).earn(b.id);
    }

    // Fire-and-forget: the backend registers the post + claim server-side,
    // but the local mock flow above stays the source of truth for the demo.
    // Deliberately NOT awaited — an unreachable backend must never delay
    // the publish UX; failures are swallowed.
    if (!Config.mock) {
      unawaited(
        ref
            .read(apiClientProvider)
            .registerPost(
              businessId: b.id,
              platform: _platform,
              caption: _caption.text,
            )
            .catchError((_) {}),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green,
        content: Text(
          b.hasPerk
              ? 'Posted. ${b.perkTitle} is pending approval.'
              : 'Posted. Scene done.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
    context.pop(); // back to step or journey
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final b = businessById(widget.businessId);
    final draft = ref.watch(strollProvider).draftFor(widget.businessId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Post · ${b.name}',
            style: titleStyle(size: 18).copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Media preview
          if (draft.hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Image.memory(
                base64Decode(draft.photoBase64!),
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    b.category.color.withValues(alpha: 0.8),
                    b.category.color.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: Icon(b.category.icon, size: 56, color: Colors.white),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (draft.hasVideo)
                _badge(CupertinoIcons.videocam_fill, 'clip attached',
                    AppColors.indigo),
              if (draft.hasVoice)
                _badge(CupertinoIcons.mic_fill,
                    'voice note · ${draft.voiceSeconds}s', AppColors.coral),
              if (draft.hasNote)
                _badge(CupertinoIcons.pencil, 'note attached',
                    AppColors.green),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Caption',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: _caption,
            maxLines: 4,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text('Platform',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _PlatformButton(
                label: 'Instagram',
                icon: CupertinoIcons.camera_fill,
                selected: _platform == 'instagram',
                gradient: AppColors.instagram,
                onTap: () => setState(() => _platform = 'instagram'),
              ),
              const SizedBox(width: 10),
              _PlatformButton(
                label: 'TikTok',
                icon: CupertinoIcons.music_note,
                selected: _platform == 'tiktok',
                color: AppColors.ink,
                onTap: () => setState(() => _platform = 'tiktok'),
              ),
              const SizedBox(width: 10),
              _PlatformButton(
                label: 'Facebook',
                icon: Icons.facebook,
                selected: _platform == 'facebook',
                color: AppColors.facebook,
                onTap: () => setState(() => _platform = 'facebook'),
              ),
            ],
          ),
          if (b.hasPerk) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: AppColors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Publishing delivers "${b.deliverable}" → earns '
                      '${b.perkTitle} (€${b.perkValue})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomSheet: Container(
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: GestureDetector(
          onTap: _publishing ? null : _publish,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Center(
              child: _publishing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Publish to ${_platform[0].toUpperCase()}${_platform.substring(1)} →',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      );
}

class _PlatformButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback onTap;

  const _PlatformButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 64,
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.text),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.text,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
