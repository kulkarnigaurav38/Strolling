import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../models.dart';
import '../seed.dart';

/// The one place the app talks to the outside world. In commit 1 every method
/// short-circuits to seeded data (real signatures, fake data) so the whole flow
/// is clickable with zero keys. Each method names the commit that makes it real.
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Config.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'Content-Type': 'application/json'},
            ));

  final Dio _dio;

  /// POST /api/tasks { business } → the 5-shot list for this venue.
  Future<List<Task>> generateTasks(Business business) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      // TODO(COMMIT-3): Claude generates from business seed
      return kFallbackTasks;
    }
    final res = await _dio.post<List<dynamic>>(
      '/api/tasks',
      data: {'business': business.toJson()},
    );
    return (res.data ?? [])
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/render { captures, reviews, business } → the finished vertical video.
  Future<RenderResult> render({
    required List<Capture> captures,
    required List<Review> reviews,
    required Business business,
  }) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(seconds: 3));
      // TODO(COMMIT-4): fal i2v + ffmpeg compose, real-voice narration
      return const RenderResult(videoUrl: 'assets/mock/sample.mp4');
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/render',
      data: {
        'captures': captures.map((c) => c.toJson()).toList(),
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'business': business.toJson(),
      },
    );
    return RenderResult.fromJson(res.data!);
  }

  /// POST /api/publish { videoUrl, transcript } → the live post + caption/hashtags.
  Future<PublishResult> publish({
    required String videoUrl,
    required String transcript,
  }) async {
    if (Config.mock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // TODO(COMMIT-5): n8n webhook → YouTube Short
      return const PublishResult(
        postUrl: 'https://youtube.com/shorts/mock',
        caption:
            'Walked into a room of 60 builders in Stuttgart and left with a film about it. '
            'One day, one city, a lot of shipping. 🍹 #hackathon',
        hashtags: [
          '#hackathon',
          '#stuttgart',
          '#cursor',
          '#buildinpublic',
          '#fernweh',
        ],
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/publish',
      data: {'videoUrl': videoUrl, 'transcript': transcript},
    );
    return PublishResult.fromJson(res.data!);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
