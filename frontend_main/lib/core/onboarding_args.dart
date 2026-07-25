import 'user_role.dart';

/// Carries onboarding choices across auth → city → interests → home.
class OnboardingArgs {
  const OnboardingArgs({
    required this.role,
    this.city,
    this.interests = const [],
  });

  final UserRole role;
  final String? city;
  final List<String> interests;

  OnboardingArgs copyWith({
    UserRole? role,
    String? city,
    List<String>? interests,
  }) {
    return OnboardingArgs(
      role: role ?? this.role,
      city: city ?? this.city,
      interests: interests ?? this.interests,
    );
  }

  static OnboardingArgs fromExtra(Object? extra) {
    if (extra is OnboardingArgs) return extra;
    if (extra is UserRole) return OnboardingArgs(role: extra);
    return const OnboardingArgs(role: UserRole.creator);
  }
}
