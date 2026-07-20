import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';

/// Search repository
class SearchRepository {
  final Dio _dio = ApiClient.instance;

  // ─── GET /search ───────────────────────────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> search({
    required String query,
    String? projectId,
    String? userId,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'page': page,
        'pageSize': pageSize,
        if (projectId != null) 'projectId': projectId,
        if (userId != null) 'userId': userId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };

      final resp = await _dio.get(
        ApiEndpoints.search,
        queryParameters: params,
      );

      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Search failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
