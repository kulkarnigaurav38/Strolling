import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/map_business.dart';
import '../../../core/stroll/script_templates.dart';
import '../../../core/stroll/stroll_controller.dart';
import '../../../core/stroll/stroll_models.dart';
import '../../../core/theme.dart';

/// Pick the script style, then start the stroll from the cart.
class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key, required this.stopIds});

  final List<int> stopIds;

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  String _selected = 'doku';
  bool _writing = false;

  List<MapBusiness> get _stops =>
      widget.stopIds.map(businessById).toList();

  Future<void> _writeScript() async {
    setState(() => _writing = true);
    // Brief mock delay so the CTA feels intentional.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    StrollScope.of(context, listen: false).start(
      widget.stopIds,
      templateId: _selected,
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    final perkCount = stops.where((b) => b.hasPerk).length;
    final template = templateById(_selected);
    final preview = template.generate(stops);

    return Scaffold(
      backgroundColor: StrollingColors.background,
      appBar: AppBar(
        backgroundColor: StrollingColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: StrollingColors.ink),
          onPressed: () => context.pop(false),
        ),
        title: Text(
          'Pick your script style',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: StrollingColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            '${stops.length} stops · $perkCount with perks — the script bends '
            'around your deliverables.',
            style: GoogleFonts.plusJakartaSans(
              color: StrollingColors.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final t in kTemplates) ...[
            _TemplateCard(
              template: t,
              selected: _selected == t.id,
              onTap: () => setState(() => _selected = t.id),
            ),
            const SizedBox(height: 12),
          ],
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'FIRST SCENE PREVIEW',
              style: GoogleFonts.nunito(
                color: StrollingColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: template.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.first.sceneTitle,
                    style: GoogleFonts.nunito(
                      color: template.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview.first.direction,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      height: 1.45,
                      color: StrollingColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '“${preview.first.line}”',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: StrollingColors.ink,
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
            onTap: _writing ? null : _writeScript,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 58,
              child: Center(
                child: _writing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Write my script →',
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
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ScriptTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = template;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? t.color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? t.color : StrollingColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 6 : 4,
              height: 52,
              decoration: BoxDecoration(
                color: t.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Icon(t.icon, size: 28, color: t.color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.name,
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: StrollingColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.tagline,
                        style: GoogleFonts.nunito(
                          color: StrollingColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.vibe,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.35,
                      color: StrollingColors.mutedAlt,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: t.color, size: 26),
          ],
        ),
      ),
    );
  }
}

/// Route extra for template picker.
class TemplateArgs {
  const TemplateArgs({required this.stopIds});
  final List<int> stopIds;
}
