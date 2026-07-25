// Build-time configuration.
// Default talks to the local Express API. Offline-only:
//
//   flutter run --dart-define=STROLLING_MOCK=true
//
// Physical device (not simulator): point at your machine LAN IP:
//
//   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
class Config {
  /// When true, ApiClient returns contract-shaped mocks without networking.
  /// When false, calls the Express API at [apiBaseUrl].
  static const bool mock = bool.fromEnvironment(
    'STROLLING_MOCK',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
