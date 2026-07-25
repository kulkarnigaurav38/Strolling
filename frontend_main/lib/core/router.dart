import 'package:go_router/go_router.dart';

import 'onboarding_args.dart';
import '../features/auth/screens/welcome_auth_screen.dart';
import '../features/business/screens/business_home_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/onboarding/screens/city_select_screen.dart';
import '../features/onboarding/screens/interests_screen.dart';
import '../features/post/screens/generating_post_screen.dart';
import '../features/post/screens/stop_post_screen.dart';
import '../features/role/screens/role_select_screen.dart';
import '../features/step/screens/step_screen.dart';
import '../features/template/screens/template_picker_screen.dart';

abstract final class AppRoutes {
  static const role = '/';
  static const auth = '/auth';
  static const city = '/city';
  static const interests = '/interests';
  static const creatorHome = '/creator';
  static const businessHome = '/business';
  static const template = '/template';
  static const step = '/step/:id';
  static const generatingPost = '/generating-post/:id';
  static const post = '/post/:id';

  static String stepPath(int id) => '/step/$id';
  static String generatingPostPath(int id) => '/generating-post/$id';
  static String postPath(int id) => '/post/$id';
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.role,
    routes: [
      GoRoute(
        path: AppRoutes.role,
        builder: (context, state) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) {
          final args = OnboardingArgs.fromExtra(state.extra);
          return WelcomeAuthScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.city,
        builder: (context, state) {
          final args = OnboardingArgs.fromExtra(state.extra);
          return CitySelectScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.interests,
        builder: (context, state) {
          final args = OnboardingArgs.fromExtra(state.extra);
          return InterestsScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.creatorHome,
        builder: (context, state) {
          final args = OnboardingArgs.fromExtra(state.extra);
          return MapScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.businessHome,
        builder: (context, state) {
          final args = OnboardingArgs.fromExtra(state.extra);
          return BusinessHomeScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.template,
        builder: (context, state) {
          final extra = state.extra;
          final stopIds = extra is TemplateArgs
              ? extra.stopIds
              : (extra is List<int> ? extra : <int>[]);
          return TemplatePickerScreen(stopIds: stopIds);
        },
      ),
      GoRoute(
        path: AppRoutes.step,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return StepScreen(businessId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.generatingPost,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return GeneratingPostScreen(businessId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.post,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return StopPostScreen(businessId: id);
        },
      ),
    ],
  );
}
