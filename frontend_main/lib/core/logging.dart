import 'package:flutter/foundation.dart';

/// Compact, filtered console logging.
///
/// Flutter's default error handler dumps a multi-line stack trace for EVERY
/// failed network image or map tile — and a stroll loads dozens of remote
/// photos/tiles, so a flaky connection floods the terminal and buries anything
/// useful. This:
///   • drops the known-noisy chatter (image/tile/socket failures) entirely, and
///   • collapses every other error to a single readable line.
///
/// Use [logInfo] for the app's own intentional, one-line breadcrumbs.
void installAppLogging() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isNoise(details.exception)) return; // swallow image/tile/network spam
    final first = details.exceptionAsString().split('\n').first;
    debugPrint('⚠ $first');
  };

  // Errors that escape the widget tree (async gaps, image stream handlers…).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (!_isNoise(error)) {
      debugPrint('⚠ ${error.toString().split('\n').first}');
    }
    return true; // handled — don't let the framework print the full dump
  };
}

/// One-line app breadcrumb (debug builds only). Prefixed so it's easy to grep.
void logInfo(String message) {
  if (kReleaseMode) return;
  debugPrint('· $message');
}

/// Failed remote images, map tiles, DNS/socket hiccups — expected on mobile
/// networks and not worth a stack trace each.
bool _isNoise(Object e) {
  final s = e.toString();
  return s.contains('NetworkImageLoadException') ||
      s.contains('EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE') ||
      s.contains('image resource service') ||
      s.contains('HttpException') ||
      s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection closed') ||
      s.contains('Connection reset') ||
      s.contains('HandshakeException') ||
      s.contains('Invalid image data');
}
