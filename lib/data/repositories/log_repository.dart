import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';

/// Log repository — all 7 daily log endpoints
class LogRepository {
  final Dio _dio = ApiClient.instance;

  String _extractMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  // ─── GET /logs/today ───────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel?>> getTodayLog() async {
    try {
      final resp = await _dio.get(ApiEndpoints.logsToday);
      if (resp.statusCode == 200) {
        return ApiSuccess(DailyLogModel.fromJson(resp.data));
      }
      if (resp.statusCode == 404 || resp.statusCode == 204) return const ApiSuccess(null); // Not logged yet
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /logs/{date} ─────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel?>> getLogByDate(String date) async {
    try {
      final resp = await _dio.get(ApiEndpoints.logByDate(date));
      if (resp.statusCode == 200) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      if (resp.statusCode == 404 || resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /logs ─────────────────────────────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getLogs({
    String? from,
    String? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.logs,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /logs ────────────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel>> createLog({
    required List<Map<String, dynamic>> entries,
  }) async {

    try {
      final resp = await _dio.post(
        ApiEndpoints.logs,
        data: {'entries': entries},
      );
      if (resp.statusCode == 201) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed to create log'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /logs/{id}/update ───────────────────────────────────────────────
  Future<ApiResult<DailyLogModel>> updateLog({
    required String logId,
    required List<Map<String, dynamic>> entries,
    List<String> deletedEntryIds = const [],
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.logUpdate(logId),
        data: {
          'entries': entries,
          'deletedEntryIds': deletedEntryIds,
        },
      );
      if (resp.statusCode == 200) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed to update log'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /logs/user/{userId} (Admin) ─────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getUserLogs(
    String userId, {
    String? from,
    String? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
      final resp = await _dio.get(ApiEndpoints.logsByUser(userId),
          queryParameters: query);
      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /logs/user/{userId}/{date} (Admin) ───────────────────────────────
  Future<ApiResult<DailyLogModel?>> getUserLogByDate(
      String userId, String date) async {
    try {
      final resp =
          await _dio.get(ApiEndpoints.logByUserAndDate(userId, date));
      if (resp.statusCode == 200) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      if (resp.statusCode == 404 || resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: _extractMessage(resp.data, 'Failed'),
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
