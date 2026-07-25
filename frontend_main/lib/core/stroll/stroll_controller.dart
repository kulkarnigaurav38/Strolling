import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stroll_models.dart';

const _kStrollKey = 'strolling.stroll.v1';

/// Active stroll: ordered stops + per-stop drafts + chosen script template.
class StrollController extends ChangeNotifier {
  StrollState _state = const StrollState();
  bool _disposed = false;

  StrollController() {
    _load();
  }

  StrollState get state => _state;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStrollKey);
    if (raw == null || _disposed) return;
    if (_state.active) return;
    try {
      _state = StrollState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_kStrollKey);
    }
  }

  Future<void> _persist() async {
    final json = jsonEncode(_state.toJson());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStrollKey, json);
  }

  void start(List<int> stopIds, {required String templateId}) {
    _state = StrollState(
      stopIds: List<int>.from(stopIds),
      drafts: {for (final id in stopIds) id: StopDraft(businessId: id)},
      templateId: templateId,
    );
    notifyListeners();
    _persist();
  }

  void updateDraft(int businessId, StopDraft draft) {
    _state = _state.copyWith(
      drafts: {..._state.drafts, businessId: draft},
    );
    notifyListeners();
    _persist();
  }

  void end() {
    _state = const StrollState();
    notifyListeners();
    _persist();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// App-wide stroll access without Riverpod — matches frontend_main's style.
class StrollScope extends InheritedNotifier<StrollController> {
  const StrollScope({
    super.key,
    required StrollController controller,
    required super.child,
  }) : super(notifier: controller);

  static StrollController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<StrollScope>()
        : context.getInheritedWidgetOfExactType<StrollScope>();
    assert(scope != null, 'StrollScope not found in widget tree');
    return scope!.notifier!;
  }
}
