import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

class AdminRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResult<Map<String, dynamic>>> getStats() async {
    try {
      final resp = await _dio.get('/admin/stats');
      if (resp.statusCode == 200) {
        return ApiSuccess(resp.data as Map<String, dynamic>);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to get stats'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getAllAttendance(String date) async {
    try {
      final resp = await _dio.get('/attendance/all', queryParameters: {'date': date});
      if (resp.statusCode == 200) {
        final data = resp.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['attendance'] ?? data['records'] ?? data['data'] ?? [];
        }
        final list = rawList.cast<Map<String, dynamic>>();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to get attendance'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<void>> regularizeAttendance(
    String userId, {
    required String punchInTime,
    required String punchOutTime,
    String? adminNotes,
  }) async {
    try {
      final resp = await _dio.post('/attendance/$userId/regularize', data: {
        'punchInTime': punchInTime,
        'punchOutTime': punchOutTime,
        'adminNotes': adminNotes,
      });
      if (resp.statusCode == 200) {
        return const ApiSuccess(null);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to regularize attendance'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
