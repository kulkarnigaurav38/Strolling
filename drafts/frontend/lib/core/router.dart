import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'state.dart';
import '../features/shell/app_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/map/map_screen.dart';
import '../features/template/template_picker_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/step/step_screen.dart';
import '../features/post/stop_post_screen.dart';
import '../features/perks/perks_screen.dart';
import '../features/profile/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<String?>(authProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/map',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(authProvider) != null;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!authed && !onOnboarding) return '/onboarding';
      if (authed && onOnboarding) return '/map';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      // Full-screen flows pushed above the tab shell.
      GoRoute(
        path: '/template',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const TemplatePickerScreen(),
      ),
      GoRoute(
        path: '/step/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => StepScreen(businessId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => StopPostScreen(businessId: s.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/stroll', builder: (_, __) => const JourneyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/perks', builder: (_, __) => const PerksScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
