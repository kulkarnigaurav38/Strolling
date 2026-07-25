import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Media storage boundary (the brief's lib/fal.ts). In commit 1 the captured
/// file path IS the media URL, so this is a pass-through — the whole flow works
/// with zero keys. Later it uploads to fal storage and returns a durable URL the
/// render pipeline can read.
class MediaStorage {
  Future<String> uploadMedia(String localPath) async {
    // TODO(COMMIT-3): fal.storage.upload → return the remote URL
    return localPath;
  }
}

final mediaStorageProvider = Provider<MediaStorage>((ref) => MediaStorage());
