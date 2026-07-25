import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/router.dart';
import '../../../core/stroll/script_templates.dart';
import '../../../core/stroll/stroll_controller.dart';
import '../../../core/stroll/stroll_models.dart';
import '../../../core/theme.dart';

/// My stroll tab — active journey timeline, or empty state.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({
    super.key,
    this.onOpenMap,
  });

  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final stroll = StrollScope.of(context).state;
    final script = scriptForStroll(stroll);

    if (!stroll.active) {
      return ColoredBox(
        color: StrollingColors.background,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.map,
                    size: 52,
                    color: StrollingColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No stroll yet',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: StrollingColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick 2+ stops on the map to build one.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: StrollingColors.muted,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (onOpenMap != null)
                    FilledButton(
                      onPressed: onOpenMap,
                      style: FilledButton.styleFrom(
                        backgroundColor: StrollingColors.primaryDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Open the map',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final template = templateById(stroll.templateId);
    final points = [
      for (final step in script) businessById(step.businessId).latLng,
    ];

    return ColoredBox(
      color: StrollingColors.background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: points.isEmpty
                      ? const ColoredBox(color: StrollingColors.surfaceMuted)
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: points.first,
                            zoom: 14.5,
                          ),
                          markers: {
                            for (var i = 0; i < points.length; i++)
                              Marker(
                                markerId: MarkerId('stop-$i'),
                                position: points[i],
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRose,
                                ),
                                infoWindow: InfoWindow(title: '${i + 1}'),
                              ),
                          },
                          polylines: points.length >= 2
                              ? {
                                  Polyline(
                                    polylineId: const PolylineId('route'),
                                    points: points,
                                    color: StrollingColors.primary,
                                    width: 4,
                                    patterns: [PatternItem.dot, PatternItem.gap(8)],
                                  ),
                                }
                              : {},
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          liteModeEnabled: true,
                          onMapCreated: (controller) {
                            if (points.length < 2) return;
                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                _boundsFor(points),
                                48,
                              ),
                            );
                          },
                        ),
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
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
                        Icon(template.icon, size: 15, color: template.color),
                        const SizedBox(width: 6),
                        Text(
                          '${template.name} · ${stroll.completedCount}/${stroll.stopIds.length} posted',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: StrollingColors.ink,
                          ),
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
                      onTap: () => _confirmEnd(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'End stroll',
                          style: GoogleFonts.nunito(
                            color: StrollingColors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
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
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == script.length) {
                  return _TotalsCard(stroll: stroll);
                }
                final step = script[i];
                final draft = stroll.draftFor(step.businessId);
                return _StopCard(
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

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _confirmEnd(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'End this stroll?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Unposted captures will be discarded.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () {
              StrollScope.of(context, listen: false).end();
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'End stroll',
              style: GoogleFonts.nunito(
                color: StrollingColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.step,
    required this.posted,
    required this.started,
    required this.satisfied,
    required this.savedAt,
    required this.color,
  });

  final ScriptStep step;
  final bool posted;
  final bool started;
  final bool satisfied;
  final DateTime? savedAt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final b = businessById(step.businessId);

    return Container(
      decoration: BoxDecoration(
        color: posted
            ? StrollingColors.success.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: posted
              ? StrollingColors.success.withValues(alpha: 0.5)
              : StrollingColors.border,
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
                      ? StrollingColors.success
                      : b.categoryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  posted ? Icons.check : b.categoryIcon,
                  size: 20,
                  color: posted ? Colors.white : b.categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.sceneTitle,
                      style: GoogleFonts.nunito(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      b.name,
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: StrollingColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (b.hasPerk)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    b.perkVal ?? '',
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFF5A623),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.direction,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: StrollingColors.muted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final a in step.actions) ...[
                Icon(
                  a.kind.icon,
                  size: 15,
                  color: a.required
                      ? StrollingColors.primary
                      : StrollingColors.muted,
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text(
                '${b.walkMin} min walk',
                style: GoogleFonts.nunito(
                  color: StrollingColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (!posted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallButton(
                    label: started ? 'Resume capture' : 'Start scene',
                    color: StrollingColors.ink,
                    onTap: () => context.push(AppRoutes.stepPath(b.id)),
                  ),
                ),
                if (started && satisfied) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallButton(
                      label: 'Post',
                      color: StrollingColors.primaryDeep,
                      onTap: () => context.push(AppRoutes.postPath(b.id)),
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
                  style: GoogleFonts.nunito(
                    color: StrollingColors.muted,
                    fontSize: 12,
                  ),
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
  const _SmallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.stroll});

  final StrollState stroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StrollingColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _total(
            Icons.directions_walk_rounded,
            '${stroll.totalWalkMinutes} min',
            'walking',
          ),
          _total(
            CupertinoIcons.gift,
            '€${stroll.totalPerkValue}',
            'perk value',
          ),
          _total(
            CupertinoIcons.film,
            '${stroll.completedCount}/${stroll.stopIds.length}',
            'scenes posted',
          ),
        ],
      ),
    );
  }

  Widget _total(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      );
}
