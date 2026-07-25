// Build-time configuration. Everything is mocked by default — the app runs
// with zero keys and zero backend. Override with --dart-define:
//
//   flutter run --dart-define=STROLLING_MOCK=false \
//               --dart-define=API_BASE_URL=http://localhost:3000
class Config {
  /// Master mock switch. When false, scripts come from the backend
  /// (POST /api/scripts) instead of the local generator.
  static const bool mock = bool.fromEnvironment(
    'STROLLING_MOCK',
    defaultValue: bool.fromEnvironment('FERNWEH_MOCK', defaultValue: true),
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
