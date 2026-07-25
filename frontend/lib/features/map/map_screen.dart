import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/copy.dart';
import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import 'widgets/business_sheet.dart';
import 'widgets/mode_switch_card.dart';

/// Where the demo user stands: the hackathon venue (INFOMOTION, Friedrichstr. 6).
const kUserLocation = LatLng(48.78397, 9.17796);

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleBusinessesProvider);
    final cart = ref.watch(cartProvider);
    final filter = ref.watch(categoryFilterProvider);

    final routePoints = [
      for (final id in cart) LatLng(businessById(id).lat, businessById(id).lng),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(48.7805, 9.1830),
                initialZoom: 14.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.strolling.app',
                ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: AppColors.coral,
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    const Marker(
                      point: kUserLocation,
                      width: 36,
                      height: 36,
                      child: _UserPulse(),
                    ),
                    for (final b in visible)
                      Marker(
                        point: LatLng(b.lat, b.lng),
                        width: 56,
                        height: 68,
                        child: _Pin(
                          business: b,
                          inCart: cart.contains(b.id),
                          onTap: () => showBusinessSheet(context, b),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Mode switch + category chips.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ModeSwitchCard(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: 'All',
                          selected: filter == null,
                          onTap: () => ref
                              .read(categoryFilterProvider.notifier)
                              .state = null,
                        ),
                        for (final c in BusinessCategory.values)
                          _Chip(
                            label: c.label,
                            selected: filter == c,
                            onTap: () => ref
                                .read(categoryFilterProvider.notifier)
                                .state = filter == c ? null : c,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Cart pill.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _CartPill(cart: cart),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Business business;
  final bool inCart;
  final VoidCallback onTap;

  const _Pin({required this.business, required this.inCart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = business;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.hasPerk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: inCart ? AppColors.green : b.category.color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inCart)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  Text(
                    '€${b.perkValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: b.hasPerk ? Colors.white : const Color(0xFFA8A39B),
              shape: BoxShape.circle,
              border: Border.all(
                color: inCart
                    ? AppColors.green
                    : (b.hasPerk ? b.category.color : Colors.white),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              b.category.icon,
              size: 19,
              color: b.hasPerk ? b.category.color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPulse extends StatefulWidget {
  const _UserPulse();

  @override
  State<_UserPulse> createState() => _UserPulseState();
}

class _UserPulseState extends State<_UserPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 18 + 18 * _c.value,
              height: 18 + 18 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    AppColors.coral.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartPill extends ConsumerWidget {
  final List<String> cart;
  const _CartPill({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = cart.length >= 2;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.sunset,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_walk_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: cart.isEmpty
                ? const Text(Copy.tapPin,
                    style: TextStyle(color: AppColors.muted, fontSize: 15))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cart.length} stop${cart.length == 1 ? '' : 's'} picked',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          for (final id in cart)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                businessById(id).category.icon,
                                size: 15,
                                color: businessById(id).category.color,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          GestureDetector(
            onTap: ready ? () => context.push('/template') : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: ready ? AppColors.coral : AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  ready ? Copy.createStroll : Copy.needStops,
                  style: TextStyle(
                    color: ready ? Colors.white : AppColors.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
