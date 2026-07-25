import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../models.dart';

/// The single client for the Strolling backend. Shapes mirror src/lib/types.ts.
/// Only used when [Config.mock] is false — the app never needs a network
/// connection while mocked.
class ApiClient {
  final Dio _dio;

  ApiClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Config.apiBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// POST /api/scripts — the per-stop shooting script for the picked stops.
  Future<List<ScriptStep>> generateScript({
    required List<String> stopIds,
    required String templateId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/scripts',
      data: {'stopIds': stopIds, 'templateId': templateId},
    );
    final steps = res.data?['steps'] as List<dynamic>? ?? const [];
    return steps
        .map((e) => ScriptStep.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
