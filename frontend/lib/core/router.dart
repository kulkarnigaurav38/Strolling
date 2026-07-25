import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'session/session_controller.dart';
import '../features/brief/screens/brief_screen.dart';
import '../features/shoot/screens/shoot_screen.dart';
import '../features/interview/screens/interview_panel.dart';
import '../features/render/screens/render_screen.dart';
import '../features/done/screens/done_screen.dart';

/// The single source of truth for what's on screen is [ShootSession.status].
/// The router is just a projection of it: whenever the status changes we redirect
/// to the matching route. This keeps the "one route, state-driven" design from the
/// brief while using go_router idiomatically.
String locationForStatus(SessionStatus status) {
  switch (status) {
    case SessionStatus.brief:
      return '/';
    case SessionStatus.shooting:
      return '/shoot';
    case SessionStatus.interview:
      return '/interview';
    case SessionStatus.rendering:
      return '/render';
    case SessionStatus.done:
      return '/done';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bump on every status change so go_router re-evaluates the redirect.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<SessionStatus>(
    sessionProvider.select((s) => s.status),
    (_, __) => refresh.value++,
  );

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final target = locationForStatus(ref.read(sessionProvider).status);
      return state.matchedLocation == target ? null : target;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const BriefScreen()),
      GoRoute(path: '/shoot', builder: (_, __) => const ShootScreen()),
      GoRoute(path: '/interview', builder: (_, __) => const InterviewPanel()),
      GoRoute(path: '/render', builder: (_, __) => const RenderScreen()),
      GoRoute(path: '/done', builder: (_, __) => const DoneScreen()),
    ],
  );
});
