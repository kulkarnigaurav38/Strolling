import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/map_business.dart';
import '../stroll/script_templates.dart';
import '../stroll/stroll_models.dart';

/// Reports render progress to the UI. [pct] is 0..1; [stage] is a short label.
typedef ProgressCallback = void Function(double pct, String stage);

/// Contract shapes mirrored from `src/lib/types.ts` (RenderResult post package).
class PostPackage {
  final String videoUrl;
  final String caption;
  final List<String> hashtags;
  final String script;

  const PostPackage({
    required this.videoUrl,
    required this.caption,
    required this.hashtags,
    required this.script,
  });

  factory PostPackage.fromJson(Map<String, dynamic> j) => PostPackage(
        videoUrl: j['videoUrl'] as String? ?? '/mock/sample.mp4',
        caption: j['caption'] as String? ?? '',
        hashtags: (j['hashtags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['#strolling'],
        script: j['script'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'videoUrl': videoUrl,
        'caption': caption,
        'hashtags': hashtags,
        'script': script,
      };

  /// Make relative /renders|/mock URLs absolute for share / open.
  String get absoluteVideoUrl {
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }
    if (videoUrl.startsWith('/')) {
      return '${Config.apiBaseUrl}$videoUrl';
    }
    return videoUrl;
  }
}

class PublishResult {
  final String postUrl;
  final String caption;
  final List<String> hashtags;

  const PublishResult({
    required this.postUrl,
    required this.caption,
    required this.hashtags,
  });

  factory PublishResult.fromJson(Map<String, dynamic> j) => PublishResult(
        postUrl: j['postUrl'] as String? ?? '',
        caption: j['caption'] as String? ?? '',
        hashtags: (j['hashtags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Result of a render call — post package plus any newly uploaded media URLs.
class RenderOutcome {
  final PostPackage package;
  final StopDraft draft;

  const RenderOutcome({required this.package, required this.draft});
}

/// Single client for the Strolling backend. Shapes mirror `src/lib/types.ts`.
/// When [Config.mock] is true, returns contract-shaped fakes with no network.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Real fal / Kling renders can take several minutes.
  static const Duration renderTimeout = Duration(minutes: 12);

  Uri _uri(String path) => Uri.parse('${Config.apiBaseUrl}$path');

  /// POST /api/media/upload (multipart field "file") → mediaUrl
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String contentType = 'application/octet-stream',
  }) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return 'mock://local/$filename';
    }

    final req = http.MultipartRequest('POST', _uri('/api/media/upload'));
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
    // Generous: a large clip over slow Wi-Fi can take a while. Videos are stored
    // locally on the server now (no slow fal hop), so this is just a safety net.
    final streamed = await _http.send(req).timeout(const Duration(minutes: 5));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('upload failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final url = data['mediaUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('upload failed: no mediaUrl');
    }
    return url;
  }

  /// POST /api/scripts { stopIds, templateId } → ScriptStep[]
  Future<List<ScriptStep>> generateScript({
    required List<int> stopIds,
    required String templateId,
  }) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return templateById(templateId)
          .generate(stopIds.map(businessById).toList());
    }

    // Prefer seed slugs (e.g. cursor-hackathon) so the API resolves INFOMOTION
    // without relying on pin-int aliases.
    final stopSlugs =
        stopIds.map((id) => businessById(id).backendId).toList();

    final res = await _http.post(
      _uri('/api/scripts'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'stopIds': stopSlugs,
        'templateId': templateId,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('scripts failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final steps = data['steps'] as List<dynamic>? ?? const [];
    return steps
        .map((e) => ScriptStep.fromApiJson(e as Map<String, dynamic>))
        .map((s) => enrichApiStep(s, templateId))
        .toList();
  }

  /// Ensure draft captures have durable mediaUrls (upload if needed).
  Future<StopDraft> ensureUploaded(
    StopDraft draft, {
    ProgressCallback? onProgress,
  }) async {
    var next = draft;

    if (draft.hasPhoto &&
        (draft.photoUrl == null || draft.photoUrl!.startsWith('mock://'))) {
      onProgress?.call(0.08, 'Uploading photo…');
      final bytes = base64Decode(draft.photoBase64!);
      final url = await uploadBytes(
        bytes: bytes,
        filename: 'photo-${draft.businessId}.jpg',
        contentType: 'image/jpeg',
      );
      next = next.copyWith(photoUrl: url);
      onProgress?.call(0.20, 'Photo uploaded');
    }

    if (draft.videoBytes != null &&
        draft.videoBytes!.isNotEmpty &&
        (draft.videoUrl == null || draft.videoUrl!.startsWith('mock://'))) {
      onProgress?.call(0.18, 'Uploading video…');
      final name = draft.videoName ?? 'clip-${draft.businessId}.mp4';
      final url = await uploadBytes(
        bytes: draft.videoBytes!,
        filename: name,
        contentType: 'video/mp4',
      );
      next = next.copyWith(videoUrl: url, clearVideoBytes: true);
      onProgress?.call(0.24, 'Video uploaded');
    }

    if (draft.voiceBytes != null &&
        draft.voiceBytes!.isNotEmpty &&
        (draft.voiceUrl == null || draft.voiceUrl!.startsWith('mock://'))) {
      onProgress?.call(0.26, 'Uploading voice note…');
      final name = draft.voiceName ?? 'voice-${draft.businessId}.m4a';
      final url = await uploadBytes(
        bytes: draft.voiceBytes!,
        filename: name,
        contentType: 'audio/mp4',
      );
      next = next.copyWith(voiceUrl: url, clearVoiceBytes: true);
      onProgress?.call(0.31, 'Voice note uploaded');
    }

    return next;
  }

  /// POST /api/render — stroll flat shape → post package.
  ///
  /// [onProgress] is called with (0..1, label) as the render advances: real
  /// upload progress, then live backend stages polled from
  /// GET /api/render/progress/:renderId while the (minutes-long) POST is in flight.
  Future<RenderOutcome> render({
    required MapBusiness business,
    required StopDraft draft,
    required ScriptStep step,
    ProgressCallback? onProgress,
  }) async {
    final script = [
      step.line,
      if (draft.hasNote) draft.note!.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    onProgress?.call(0.02, 'Preparing…');
    final ready = Config.mock ? draft : await ensureUploaded(draft, onProgress: onProgress);
    final renderId = _newRenderId();

    final body = <String, dynamic>{
      'renderId': renderId,
      'script': script,
      'text': draft.note ?? step.line,
      'business': {
        'slug': business.backendId,
        'name': business.name,
        'venue': business.desc,
        'incentive': business.perk ?? '',
        'vibe': business.category,
        'style': 'vertical mini-doc',
      },
      if (ready.videoUrl != null && !ready.videoUrl!.startsWith('mock://'))
        'videoUrl': ready.videoUrl,
      if (ready.photoUrl != null && !ready.photoUrl!.startsWith('mock://'))
        'images': [ready.photoUrl],
      // The creator's raw voice note. The backend transcribes it, polishes it
      // into a narration script, and re-voices it — so the narration carries
      // their own opinions. If absent, narration falls back to the script/TTS.
      if (ready.voiceUrl != null && !ready.voiceUrl!.startsWith('mock://'))
        'voiceNoteUrl': ready.voiceUrl,
    };

    if (Config.mock) {
      onProgress?.call(0.5, 'Cutting it together…');
      await Future<void>.delayed(const Duration(milliseconds: 900));
      onProgress?.call(1.0, 'Ready');
      return RenderOutcome(
        draft: ready,
        package: PostPackage(
          videoUrl: '/mock/sample.mp4',
          caption:
              '${script.isEmpty ? business.name : script.split(RegExp(r'(?<=[.!?])\s+')).first} 📍 ${business.name}\n\n#strolling #stuttgart',
          hashtags: const [
            '#strolling',
            '#stuttgart',
            '#walkandshoot',
            '#minidoc',
            '#localgems',
          ],
          script:
              script.isEmpty ? 'A short film from ${business.name}.' : script,
        ),
      );
    }

    onProgress?.call(0.32, 'Sending to the studio…');
    final postFuture = _http
        .post(
          _uri('/api/render'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(renderTimeout);

    // Poll live backend progress in parallel until the POST resolves. Backend
    // 0..100 is mapped into the 0.32..0.98 slice we reserve for rendering.
    await _pollUntilDone(renderId, postFuture, onProgress);

    final res = await postFuture;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('render failed: ${res.statusCode} ${res.body}');
    }
    onProgress?.call(1.0, 'Ready');
    return RenderOutcome(
      draft: ready,
      package: PostPackage.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      ),
    );
  }

  /// A short, unique id to correlate a render with its progress endpoint.
  String _newRenderId() =>
      'r${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Poll GET /api/render/progress/:id every ~1.2s, forwarding real stages to
  /// [onProgress], until [postFuture] completes. Poll failures are ignored — a
  /// missing/late progress row must never break the render itself.
  Future<void> _pollUntilDone(
    String renderId,
    Future<http.Response> postFuture,
    ProgressCallback? onProgress,
  ) async {
    if (onProgress == null) return;
    var done = false;
    unawaited(postFuture.whenComplete(() => done = true).catchError(
          (_) => http.Response('', 599), // swallow here; real await handles it
        ));
    while (!done) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (done) break;
      try {
        final pr = await _http
            .get(_uri('/api/render/progress/$renderId'))
            .timeout(const Duration(seconds: 4));
        if (pr.statusCode == 200) {
          final j = jsonDecode(pr.body) as Map<String, dynamic>;
          final pct = (j['pct'] as num?)?.toDouble() ?? 0;
          final stage = (j['stage'] as String?) ?? 'Rendering…';
          if (!done) onProgress(0.32 + 0.66 * (pct / 100.0), stage);
        }
      } catch (_) {
        // ignore poll errors (row not ready yet, transient network)
      }
    }
  }

  /// POST /api/publish { videoUrl, transcript } → { postUrl, caption, hashtags }
  Future<PublishResult> publish({
    required String videoUrl,
    required String transcript,
  }) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return PublishResult(
        postUrl: 'https://youtube.com/shorts/mock',
        caption: transcript,
        hashtags: const ['#strolling', '#stuttgart'],
      );
    }

    final absolute = videoUrl.startsWith('/')
        ? '${Config.apiBaseUrl}$videoUrl'
        : videoUrl;

    final res = await _http.post(
      _uri('/api/publish'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'videoUrl': absolute,
        'transcript': transcript,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('publish failed: ${res.statusCode} ${res.body}');
    }
    return PublishResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// POST /api/posts — records the published post AND advances the creator's
  /// claim to 'posted' server-side, which is what makes the post show up on the
  /// business dashboard and the perk land in the wallet.
  ///
  /// [businessId] must be the API slug (MapBusiness.apiId), not the pin int.
  /// Best-effort: callers should not block the publish UX on this.
  Future<void> registerPost({
    required String businessId,
    required String platform,
    String? caption,
    String? url,
    String userId = 'demo-user',
  }) async {
    if (Config.mock) return;
    final res = await _http
        .post(
          _uri('/api/posts'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'businessId': businessId,
            'platform': platform,
            if (caption != null && caption.isNotEmpty) 'caption': caption,
            if (url != null && url.isNotEmpty) 'url': url,
          }),
        )
        .timeout(const Duration(seconds: 5));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('registerPost failed: ${res.statusCode} ${res.body}');
    }
  }
}

/// App-wide singleton — frontend_main has no Riverpod.
final apiClient = ApiClient();
