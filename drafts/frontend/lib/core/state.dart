// All app state in one place: auth, map mode/filter, the stop cart, the active
// stroll (drafts keyed by business ID, per v5), and the perk wallet.
// Stroll + perks persist via shared_preferences so a mid-stroll restart resumes.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'seed.dart';

const _kStrollKey = 'strolling.stroll.v1';
const _kPerksKey = 'strolling.perks.v1';
const _kAuthKey = 'strolling.auth.v1';

/// 'instagram' | 'facebook' | 'google' | 'guest' | null (not onboarded yet).
final authProvider = StateNotifierProvider<AuthController, String?>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<String?> {
  AuthController() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Never clobber a sign-in that happened while the read was in flight.
    if (state == null) state = prefs.getString(_kAuthKey);
  }

  Future<void> signIn(String provider) async {
    state = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuthKey, provider);
  }

  Future<void> signOut() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthKey);
  }
}

final modeProvider = StateProvider<StrollMode>((_) => StrollMode.roam);

/// null = All categories.
final categoryFilterProvider = StateProvider<BusinessCategory?>((_) => null);

final scriptStyleProvider = StateProvider<ScriptStyle>((_) => ScriptStyle.cityStory);

/// Businesses visible on the map for the current mode + filter.
final visibleBusinessesProvider = Provider<List<Business>>((ref) {
  final mode = ref.watch(modeProvider);
  final filter = ref.watch(categoryFilterProvider);
  return kBusinesses.where((b) {
    if (mode == StrollMode.earn && !b.hasPerk) return false;
    if (filter != null && b.category != filter) return false;
    return true;
  }).toList();
});

/// The cart: business IDs picked on the map, in tap order.
final cartProvider = StateNotifierProvider<CartController, List<String>>(
  (ref) => CartController(),
);

class CartController extends StateNotifier<List<String>> {
  CartController() : super(const []);

  void toggle(String businessId) {
    state = state.contains(businessId)
        ? state.where((id) => id != businessId).toList()
        : [...state, businessId];
  }

  void clear() => state = const [];
}

/// The active stroll — ordered stops + a draft per stop + the chosen script
/// template (Wes / Kubrick / Doku / Viral). [fetchedSteps] holds a backend-
/// written script (when the mock flag is off); null → generate locally.
class StrollState {
  final List<String> stopIds;
  final Map<String, StopDraft> drafts;
  final String templateId;
  final List<ScriptStep>? fetchedSteps;

  const StrollState({
    this.stopIds = const [],
    this.drafts = const {},
    this.templateId = 'doku',
    this.fetchedSteps,
  });

  bool get active => stopIds.isNotEmpty;

  StopDraft draftFor(String businessId) =>
      drafts[businessId] ?? StopDraft(businessId: businessId);

  int get completedCount =>
      stopIds.where((id) => drafts[id]?.posted ?? false).length;

  bool get allDone => active && completedCount == stopIds.length;

  int get totalPerkValue => stopIds
      .map(businessById)
      .where((b) => b.hasPerk)
      .fold(0, (sum, b) => sum + (b.perkValue ?? 0));

  int get totalWalkMinutes =>
      stopIds.map(businessById).fold(0, (sum, b) => sum + b.walkMinutes);

  StrollState copyWith({
    List<String>? stopIds,
    Map<String, StopDraft>? drafts,
    String? templateId,
  }) =>
      StrollState(
        stopIds: stopIds ?? this.stopIds,
        drafts: drafts ?? this.drafts,
        templateId: templateId ?? this.templateId,
        fetchedSteps: fetchedSteps,
      );

  factory StrollState.fromJson(Map<String, dynamic> j) => StrollState(
        stopIds: (j['stopIds'] as List<dynamic>).cast<String>(),
        drafts: (j['drafts'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, StopDraft.fromJson(v as Map<String, dynamic>)),
        ),
        templateId: j['templateId'] as String? ?? 'doku',
        fetchedSteps: (j['fetchedSteps'] as List<dynamic>?)
            ?.map((e) => ScriptStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'stopIds': stopIds,
        'drafts': drafts.map((k, v) => MapEntry(k, v.toJson())),
        'templateId': templateId,
        'fetchedSteps': fetchedSteps?.map((s) => s.toJson()).toList(),
      };
}

final strollProvider = StateNotifierProvider<StrollController, StrollState>(
  (ref) => StrollController(),
);

class StrollController extends StateNotifier<StrollState> {
  StrollController() : super(const StrollState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStrollKey);
    if (raw == null) return;
    // A stroll started while the read was in flight wins over the stored one.
    if (state.active) return;
    try {
      state = StrollState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupt draft never blocks the app — start fresh.
      await prefs.remove(_kStrollKey);
    }
  }

  Future<void> _persist() async {
    // Snapshot before awaiting — state must not change under the write.
    final json = jsonEncode(state.toJson());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStrollKey, json);
  }

  void start(
    List<String> stopIds, {
    required String templateId,
    List<ScriptStep>? fetchedSteps,
  }) {
    state = StrollState(
      stopIds: stopIds,
      drafts: {for (final id in stopIds) id: StopDraft(businessId: id)},
      templateId: templateId,
      fetchedSteps: fetchedSteps,
    );
    _persist();
  }

  void updateDraft(String businessId, StopDraft draft) {
    state = state.copyWith(drafts: {...state.drafts, businessId: draft});
    _persist();
  }

  void end() {
    state = const StrollState();
    _persist();
  }
}

final perksProvider = StateNotifierProvider<PerksController, List<Perk>>(
  (ref) => PerksController(),
);

class PerksController extends StateNotifier<List<Perk>> {
  PerksController() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPerksKey);
    if (raw == null) return;
    // A perk earned while the read was in flight wins over the stored list.
    if (state.isNotEmpty) return;
    try {
      state = (jsonDecode(raw) as List<dynamic>)
          .map((e) => Perk.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await prefs.remove(_kPerksKey);
    }
  }

  Future<void> _persist() async {
    final json = jsonEncode(state.map((p) => p.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPerksKey, json);
  }

  /// Publishing a stop earns its perk (pending until the business approves —
  /// mocked: auto-approves after [approveAfter]).
  void earn(String businessId, {Duration approveAfter = const Duration(seconds: 6)}) {
    if (state.any((p) => p.businessId == businessId)) return;
    state = [
      ...state,
      Perk(businessId: businessId, status: PerkStatus.pending, earnedAt: DateTime.now()),
    ];
    _persist();
    Future.delayed(approveAfter, () => approve(businessId));
  }

  void approve(String businessId) {
    if (!mounted) return;
    state = [
      for (final p in state)
        p.businessId == businessId && p.status == PerkStatus.pending
            ? p.copyWith(status: PerkStatus.approved)
            : p,
    ];
    _persist();
  }

  void redeem(String businessId) {
    state = [
      for (final p in state)
        p.businessId == businessId ? p.copyWith(status: PerkStatus.redeemed) : p,
    ];
    _persist();
  }
}

/// Notification dot on the Perks tab: any perk ready to redeem.
final perkReadyProvider = Provider<bool>(
  (ref) => ref.watch(perksProvider).any((p) => p.status == PerkStatus.approved),
);
