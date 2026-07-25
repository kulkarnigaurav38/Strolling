import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/script_templates.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// Pick the script style for this stroll — the director picker reborn.
/// Selecting a card lights its colored border; "Write my script" builds the
/// stroll from the cart with that template.
class TemplatePickerScreen extends ConsumerStatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  ConsumerState<TemplatePickerScreen> createState() =>
      _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends ConsumerState<TemplatePickerScreen> {
  String _selected = 'doku';
  bool _writing = false;

  Future<void> _writeScript(List<String> cart) async {
    setState(() => _writing = true);
    List<ScriptStep>? fetched;
    if (!Config.mock) {
      try {
        // The backend writes the script (Claude later); local generator is
        // the offline fallback so the demo never dies on a dropped connection.
        fetched = await ref.read(apiClientProvider).generateScript(
              stopIds: cart,
              templateId: _selected,
            );
      } catch (_) {
        fetched = null;
      }
    }
    if (!mounted) return;
    ref.read(strollProvider.notifier).start(
          cart,
          templateId: _selected,
          fetchedSteps: fetched,
        );
    ref.read(cartProvider.notifier).clear();
    context.go('/stroll');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final stops = cart.map(businessById).toList();
    final perkCount = stops.where((b) => b.hasPerk).length;
    final template = templateById(_selected);
    final preview = template.generate(stops);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick your script style', style: titleStyle(size: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            '${stops.length} stops · $perkCount with perks — the script bends '
            'around your deliverables.',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
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
            const Text('First scene preview',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: template.color.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.first.sceneTitle,
                    style: TextStyle(
                      color: template.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(preview.first.direction,
                      style: const TextStyle(fontSize: 15, height: 1.45)),
                  const SizedBox(height: 10),
                  Text(
                    '“${preview.first.line}”',
                    style: titleStyle(size: 16, color: AppColors.text)
                        .copyWith(fontWeight: FontWeight.w600),
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
          onTap: _writing ? null : () => _writeScript(cart),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _writing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Write my script →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
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
  final ScriptTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

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
          borderRadius: BorderRadius.circular(AppRadius.card),
          // Uniform border only — mixed side colors + borderRadius don't paint.
          border: Border.all(
            color: selected ? t.color : AppColors.border,
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
                      Text(t.name,
                          style: titleStyle(size: 19)
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(t.tagline,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.vibe,
                      style: const TextStyle(fontSize: 13.5, height: 1.35)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: t.color, size: 26),
          ],
        ),
      ),
    );
  }
}
