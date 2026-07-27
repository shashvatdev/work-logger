import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';

/// Log repository — all 7 daily log endpoints
class LogRepository {
  final Dio _dio = ApiClient.instance;

  // ─── GET /logs/today ───────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel?>> getTodayLog() async {
    try {
      final resp = await _dio.get(ApiEndpoints.logsToday);
      if (resp.statusCode == 200) {
        return ApiSuccess(DailyLogModel.fromJson(resp.data));
      }
      if (resp.statusCode == 404) return const ApiSuccess(null); // Not logged yet
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed',
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
      if (resp.statusCode == 404) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed',
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
        message: resp.data?['message'] ?? 'Failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /logs ────────────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel>> createLog({
    required List<Map<String, String>> entries,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.logs,
        data: {'entries': entries},
      );
      if (resp.statusCode == 201) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed to create log',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── PUT /logs/{id} ───────────────────────────────────────────────────────
  Future<ApiResult<DailyLogModel>> updateLog({
    required String logId,
    required List<Map<String, dynamic>> entries,
    List<String> deletedEntryIds = const [],
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.logById(logId),
        data: {
          'entries': entries,
          'deletedEntryIds': deletedEntryIds,
        },
      );
      if (resp.statusCode == 200) return ApiSuccess(DailyLogModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed to update log',
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
        message: resp.data?['message'] ?? 'Failed',
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
      if (resp.statusCode == 404) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
