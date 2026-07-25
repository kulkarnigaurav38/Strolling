import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/map_business.dart';
import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/stroll/stroll_controller.dart';
import '../../../core/theme.dart';
import '../../journey/screens/journey_screen.dart';
import '../../perks/screens/my_perks_screen.dart';
import '../../profile/data/sample_profile.dart';
import '../../profile/screens/profile_screen.dart';
import '../../template/screens/template_picker_screen.dart';
import '../data/sample_businesses.dart';
import '../widgets/business_sheet.dart';
import '../widgets/cart_pill.dart';
import '../widgets/city_map_view.dart';
import '../widgets/map_bottom_nav.dart';
import '../widgets/mode_switch_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.args});

  final OnboardingArgs args;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapMode _mode = MapMode.explore;
  MapTab _tab = MapTab.explore;
  String _filter = 'All';
  int? _selectedId;
  final List<int> _cart = [];

  List<MapBusiness> get _visible {
    var list = kSampleBusinesses;
    if (_mode == MapMode.earn) {
      list = list.where((b) => b.hasPerk).toList();
    }
    if (_filter != 'All') {
      list = list.where((b) => b.filterKey == _filter).toList();
    }
    return list;
  }

  MapBusiness? get _selected {
    if (_selectedId == null) return null;
    for (final b in kSampleBusinesses) {
      if (b.id == _selectedId) return b;
    }
    return null;
  }

  void _togglePin(int id) {
    setState(() {
      _selectedId = _selectedId == id ? null : id;
    });
  }

  void _addToCart(int id) {
    setState(() {
      if (!_cart.contains(id) && _cart.length < 5) {
        _cart.add(id);
      }
    });
  }

  void _removeFromCart(int id) {
    setState(() => _cart.remove(id));
  }

  Future<void> _createStroll() async {
    if (_cart.length < 2) return;
    final started = await context.push<bool>(
      AppRoutes.template,
      extra: TemplateArgs(stopIds: List<int>.from(_cart)),
    );
    if (!mounted) return;
    if (started == true) {
      setState(() {
        _cart.clear();
        _selectedId = null;
        _tab = MapTab.stroll;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the active stroll changes (e.g. end stroll, publish).
    StrollScope.of(context);

    return Scaffold(
      backgroundColor: StrollingColors.background,
      body: Column(
        children: [
          Expanded(
            child: switch (_tab) {
              MapTab.explore => _buildExplore(),
              MapTab.stroll => JourneyScreen(
                  onOpenMap: () => setState(() => _tab = MapTab.explore),
                ),
              MapTab.perks => const MyPerksScreen(),
              MapTab.profile => ProfileScreen(
                  persona: buildSamplePersona(
                    city: widget.args.city,
                    interests: widget.args.interests,
                  ),
                  onLogout: () => context.go(AppRoutes.role),
                ),
            },
          ),
          MapBottomNav(
            active: _tab,
            onSelect: (t) => setState(() {
              _tab = t;
              if (t != MapTab.explore) _selectedId = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildExplore() {
    final selected = _selected;
    return Stack(
      children: [
        Positioned.fill(
          child: CityMapView(
            businesses: _visible,
            cart: _cart,
            selectedId: _selectedId,
            onPinTap: _togglePin,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              ModeSwitchCard(
                mode: _mode,
                onSwitch: (m) => setState(() {
                  _mode = m;
                  _selectedId = null;
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kMapFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = kMapFilters[i];
                    final active = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _filter = f;
                        _selectedId = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? StrollingColors.ink : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : StrollingColors.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BusinessSheet(
              business: selected,
              inCart: _cart.contains(selected.id),
              onAdd: () => _addToCart(selected.id),
              onRemove: () => _removeFromCart(selected.id),
              onClose: () => setState(() => _selectedId = null),
            ),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: CartPill(
                cart: _cart,
                businesses: kSampleBusinesses,
                onCreateStroll: _createStroll,
              ),
            ),
          ),
      ],
    );
  }
}
