import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/copy.dart';
import '../../core/models.dart';
import '../../core/script_templates.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// The active stroll: mini-map header with the route, the themed script
/// timeline, per-stop status (start / resume / posted), and totals.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stroll = ref.watch(strollProvider);
    final script = ref.watch(strollScriptProvider);

    if (!stroll.active) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.map,
                  size: 52, color: AppColors.muted),
              const SizedBox(height: 12),
              Text('No stroll yet', style: titleStyle(size: 24)),
              const SizedBox(height: 6),
              const Text(
                'Pick 2+ stops on the map to build one.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => context.go('/map'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Text(
                    'Open the map',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final template = templateById(stroll.templateId);
    final route = [
      for (final step in script)
        LatLng(businessById(step.businessId).lat,
            businessById(step.businessId).lng),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: route.isEmpty
                      ? const ColoredBox(color: AppColors.border)
                      : FlutterMap(
                          options: MapOptions(
                            initialCameraFit: CameraFit.coordinates(
                              coordinates: route,
                              padding: const EdgeInsets.all(48),
                            ),
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'dev.strolling.app',
                            ),
                            if (route.length >= 2)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: route,
                                    strokeWidth: 4,
                                    color: AppColors.coral,
                                    pattern: const StrokePattern.dotted(),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                for (var i = 0; i < route.length; i++)
                                  Marker(
                                    point: route[i],
                                    width: 26,
                                    height: 26,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(template.icon,
                            size: 15, color: template.color),
                        const SizedBox(width: 6),
                        Text(
                          '${template.name} · ${stroll.completedCount}/${stroll.stopIds.length} posted',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => _confirmEnd(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text('End stroll',
                            style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList.separated(
              itemCount: script.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == script.length) {
                  return _TotalsCard(stroll: stroll);
                }
                final step = script[i];
                final draft = stroll.draftFor(step.businessId);
                return _StopCard(
                  index: i,
                  step: step,
                  posted: draft.posted,
                  started: draft.hasAnyCapture,
                  satisfied: step.satisfiedBy(draft),
                  savedAt: draft.savedAt,
                  color: template.color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEnd(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End this stroll?'),
        content: const Text('Unposted captures will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () {
              ref.read(strollProvider.notifier).end();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('End stroll',
                style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final int index;
  final ScriptStep step;
  final bool posted;
  final bool started;
  final bool satisfied;
  final DateTime? savedAt;
  final Color color;

  const _StopCard({
    required this.index,
    required this.step,
    required this.posted,
    required this.started,
    required this.satisfied,
    required this.savedAt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final b = businessById(step.businessId);

    return Container(
      decoration: BoxDecoration(
        color: posted ? AppColors.green.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: posted ? AppColors.green.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: posted
                      ? AppColors.green
                      : b.category.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  posted ? Icons.check : b.category.icon,
                  size: 20,
                  color: posted ? Colors.white : b.category.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.sceneTitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        )),
                    Text(b.name,
                        style: titleStyle(size: 18, weight: FontWeight.w700)),
                  ],
                ),
              ),
              if (b.hasPerk)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('€${b.perkValue}',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.direction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final a in step.actions) ...[
                Icon(a.kind.icon,
                    size: 15,
                    color: a.required ? AppColors.coral : AppColors.muted),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text('${b.walkMinutes} min walk',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          if (!posted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallButton(
                    label: started ? Copy.resumeCapture : 'Start scene',
                    color: AppColors.ink,
                    onTap: () => context.push('/step/${b.id}'),
                  ),
                ),
                if (started && satisfied) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallButton(
                      label: 'Post',
                      color: AppColors.coral,
                      onTap: () => context.push('/post/${b.id}'),
                    ),
                  ),
                ],
              ],
            ),
            if (savedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Draft saved ${_ago(savedAt!)}',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    return '${d.inHours} h ago';
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final StrollState stroll;
  const _TotalsCard({required this.stroll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _total(Icons.directions_walk_rounded,
              '${stroll.totalWalkMinutes} min', 'walking'),
          _total(CupertinoIcons.gift, '€${stroll.totalPerkValue}',
              'perk value'),
          _total(CupertinoIcons.film,
              '${stroll.completedCount}/${stroll.stopIds.length}',
              'scenes posted'),
        ],
      ),
    );
  }

  Widget _total(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      );
}
