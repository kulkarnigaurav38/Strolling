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

  /// Map renderer. Defaults to OpenStreetMap (flutter_map), which needs no API
  /// key and therefore always works. Switch to Google Maps only once the key is
  /// in place AND the Maps JavaScript API (web) / Maps SDK for Android are
  /// enabled on the Cloud project — otherwise Google renders an error overlay:
  ///
  ///   flutter run --dart-define=USE_GOOGLE_MAPS=true
  static const bool useGoogleMaps = bool.fromEnvironment(
    'USE_GOOGLE_MAPS',
    defaultValue: false,
  );

  /// Mapbox public access token (`pk.…`). When set, the map renders Mapbox
  /// raster tiles instead of OpenStreetMap. Keep it out of git — pass it at
  /// build time:
  ///
  ///   flutter run --dart-define=MAPBOX_TOKEN=pk.xxx
  ///
  /// Empty → OpenStreetMap tiles (no token needed).
  static const String mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

  /// Mapbox style to render. Other good options:
  /// `mapbox/light-v11`, `mapbox/outdoors-v12`, or your own `user/styleid`.
  static const String mapboxStyle = String.fromEnvironment(
    'MAPBOX_STYLE',
    defaultValue: 'mapbox/streets-v12',
  );

  static bool get useMapbox => mapboxToken.isNotEmpty;

  /// Basemap style when no Mapbox token is set. All of these are **keyless**.
  ///
  ///   carto-voyager  (default) clean, warm, subtle colour — suits the palette
  ///   carto-positron           very light, almost monochrome; pins pop hardest
  ///   carto-dark               dark mode
  ///   osm                      classic OpenStreetMap (busiest)
  ///   esri-satellite           aerial imagery
  ///
  ///   flutter run --dart-define=MAP_STYLE=carto-positron
  static const String mapStyle = String.fromEnvironment(
    'MAP_STYLE',
    defaultValue: 'carto-voyager',
  );
}
