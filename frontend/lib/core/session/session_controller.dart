import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Single source of truth for the shoot. Every mutator is a pure state
/// transition mirrored to shared_preferences, so a mid-shoot app restart
/// resumes exactly where the creator left off.
class SessionController extends StateNotifier<ShootSession> {
  SessionController() : super(ShootSession.empty()) {
    _load();
  }

  static const _key = 'fernweh:session:v1';
  SharedPreferences? _prefs;

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        state = ShootSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Corrupt/unavailable storage → stay on the empty session.
    }
  }

  Future<void> _persist() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {
      // Best-effort; the demo still works in-memory.
    }
  }

  void _set(ShootSession next) {
    state = next;
    _persist();
  }

  void startShoot(List<Task> tasks) {
    _set(ShootSession(
      status: SessionStatus.shooting,
      currentTaskIndex: 0,
      tasks: tasks,
      captures: const [],
      reviews: const [],
    ));
  }

  void addCapture(Capture c) {
    // one capture per task — replace if the creator re-shoots
    final captures = [
      ...state.captures.where((x) => x.taskId != c.taskId),
      c,
    ];
    _set(state.copyWith(captures: captures, status: SessionStatus.interview));
  }

  void addReview(Review r) {
    final reviews = [
      ...state.reviews.where((x) => x.taskId != r.taskId),
      r,
    ];
    final isLast = state.currentTaskIndex >= state.tasks.length - 1;
    _set(state.copyWith(
      reviews: reviews,
      currentTaskIndex:
          isLast ? state.currentTaskIndex : state.currentTaskIndex + 1,
      status: isLast ? SessionStatus.rendering : SessionStatus.shooting,
    ));
  }

  void setRender(RenderResult r) {
    _set(state.copyWith(videoUrl: r.videoUrl));
  }

  void setPublish(PublishResult p) {
    _set(state.copyWith(
      postUrl: p.postUrl,
      caption: p.caption,
      hashtags: p.hashtags,
      status: SessionStatus.done,
    ));
  }

  void reset() {
    state = ShootSession.empty();
    _prefs?.remove(_key);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, ShootSession>((ref) {
  return SessionController();
});
