// Build-time configuration. The Flutter analogue of the brief's .env / NEXT_PUBLIC_MOCK.
//
// Pass overrides with --dart-define, e.g.:
//   flutter run --dart-define=FERNWEH_MOCK=0 --dart-define=API_BASE_URL=https://api.fernweh.app
//
// In commit 1 everything is mocked and the app runs with ZERO values set.
class Config {
  /// Master mock switch. Defaults ON so the app runs with no keys. Later commits
  /// flip individual routes to real integrations; this stays the demo switch.
  static const bool mock =
      bool.fromEnvironment('FERNWEH_MOCK', defaultValue: true);

  /// Base URL for the (future) backend. Unused while [mock] is true.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Populated in later commits — kept here so keys live in one place.
  static const String anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY'); // COMMIT-3
  static const String falKey = String.fromEnvironment('FAL_KEY'); // COMMIT-3/4
  static const String elevenLabsAgentId =
      String.fromEnvironment('ELEVENLABS_AGENT_ID'); // COMMIT-2
  static const String n8nWebhookUrl =
      String.fromEnvironment('N8N_WEBHOOK_URL'); // COMMIT-5
}
