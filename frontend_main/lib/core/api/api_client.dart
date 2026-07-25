import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/map_business.dart';
import '../stroll/script_templates.dart';
import '../stroll/stroll_models.dart';

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
    final streamed = await _http.send(req).timeout(const Duration(minutes: 2));
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
  Future<StopDraft> ensureUploaded(StopDraft draft) async {
    var next = draft;

    if (draft.hasPhoto &&
        (draft.photoUrl == null || draft.photoUrl!.startsWith('mock://'))) {
      final bytes = base64Decode(draft.photoBase64!);
      final url = await uploadBytes(
        bytes: bytes,
        filename: 'photo-${draft.businessId}.jpg',
        contentType: 'image/jpeg',
      );
      next = next.copyWith(photoUrl: url);
    }

    if (draft.videoBytes != null &&
        draft.videoBytes!.isNotEmpty &&
        (draft.videoUrl == null || draft.videoUrl!.startsWith('mock://'))) {
      final name = draft.videoName ?? 'clip-${draft.businessId}.mp4';
      final url = await uploadBytes(
        bytes: draft.videoBytes!,
        filename: name,
        contentType: 'video/mp4',
      );
      next = next.copyWith(videoUrl: url, clearVideoBytes: true);
    }

    return next;
  }

  /// POST /api/render — stroll flat shape → post package.
  Future<RenderOutcome> render({
    required MapBusiness business,
    required StopDraft draft,
    required ScriptStep step,
  }) async {
    final script = [
      step.line,
      if (draft.hasNote) draft.note!.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    final ready = Config.mock ? draft : await ensureUploaded(draft);

    final body = <String, dynamic>{
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
      // Voice notes aren't recorded as files yet — narration comes from script TTS.
    };

    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
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

    final res = await _http
        .post(
          _uri('/api/render'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(renderTimeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('render failed: ${res.statusCode} ${res.body}');
    }
    return RenderOutcome(
      draft: ready,
      package: PostPackage.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      ),
    );
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
