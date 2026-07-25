import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/stroll/stroll_controller.dart';
import '../../../core/stroll/stroll_models.dart';
import '../../../core/theme.dart';

/// Per-stop post builder: media preview, caption, platform, mock publish.
class StopPostScreen extends StatefulWidget {
  const StopPostScreen({super.key, required this.businessId});

  final int businessId;

  @override
  State<StopPostScreen> createState() => _StopPostScreenState();
}

class _StopPostScreenState extends State<StopPostScreen> {
  late final TextEditingController _caption;
  String _platform = 'instagram';
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(
      text: draftCaption(businessById(widget.businessId)),
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final controller = StrollScope.of(context, listen: false);
    final draft = controller.state.draftFor(widget.businessId);
    controller.updateDraft(
      widget.businessId,
      draft.copyWith(posted: true, postedPlatform: _platform),
    );
    final b = businessById(widget.businessId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: StrollingColors.success,
        behavior: SnackBarBehavior.floating,
        content: Text(
          b.hasPerk
              ? 'Posted. ${b.perk} is pending approval.'
              : 'Posted. Scene done.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
    );
    context.pop();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final b = businessById(widget.businessId);
    final draft =
        StrollScope.of(context).state.draftFor(widget.businessId);

    return Scaffold(
      backgroundColor: StrollingColors.background,
      appBar: AppBar(
        backgroundColor: StrollingColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: StrollingColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post · ${b.name}',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: StrollingColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (draft.hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                    b.categoryColor.withValues(alpha: 0.8),
                    b.categoryColor.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Icon(b.categoryIcon, size: 56, color: Colors.white),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (draft.hasVideo)
                _badge(
                  CupertinoIcons.videocam_fill,
                  'clip attached',
                  const Color(0xFF6C63FF),
                ),
              if (draft.hasVoice)
                _badge(
                  CupertinoIcons.mic_fill,
                  'voice note · ${draft.voiceSeconds}s',
                  StrollingColors.primary,
                ),
              if (draft.hasNote)
                _badge(
                  CupertinoIcons.pencil,
                  'note attached',
                  StrollingColors.success,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CAPTION',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
              color: StrollingColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caption,
            maxLines: 4,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: StrollingColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: StrollingColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PLATFORM',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
              color: StrollingColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PlatformButton(
                label: 'Instagram',
                icon: CupertinoIcons.camera_fill,
                selected: _platform == 'instagram',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                onTap: () => setState(() => _platform = 'instagram'),
              ),
              const SizedBox(width: 10),
              _PlatformButton(
                label: 'TikTok',
                icon: CupertinoIcons.music_note,
                selected: _platform == 'tiktok',
                color: StrollingColors.ink,
                onTap: () => setState(() => _platform = 'tiktok'),
              ),
              const SizedBox(width: 10),
              _PlatformButton(
                label: 'Facebook',
                icon: Icons.facebook,
                selected: _platform == 'facebook',
                color: StrollingColors.facebook,
                onTap: () => setState(() => _platform = 'facebook'),
              ),
            ],
          ),
          if (b.hasPerk) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFFF5A623)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Publishing delivers "${b.required}" → earns '
                      '${b.perk} (${b.perkVal})',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: StrollingColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomSheet: Container(
        color: StrollingColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Material(
          color: StrollingColors.primaryDeep,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _publishing ? null : _publish,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 58,
              child: Center(
                child: _publishing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Publish to ${_platform[0].toUpperCase()}${_platform.substring(1)} →',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
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
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              text,
              style: GoogleFonts.nunito(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
}

class _PlatformButton extends StatelessWidget {
  const _PlatformButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.gradient,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback onTap;

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
              color: selected ? Colors.transparent : StrollingColors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : StrollingColors.ink,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : StrollingColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
