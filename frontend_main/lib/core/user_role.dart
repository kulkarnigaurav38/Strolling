enum UserRole {
  creator,
  business,
  browse,
}

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.creator => 'Creator',
        UserRole.business => 'Business',
        UserRole.browse => 'Browse',
      };

  String get description => switch (this) {
        UserRole.creator => 'Walk routes, capture moments, earn perks.',
        UserRole.business => 'Invite creators and host strolls at your place.',
        UserRole.browse => 'Explore the city without signing in.',
      };
}
