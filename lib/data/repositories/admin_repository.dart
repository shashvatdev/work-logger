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
      Response resp;
      try {
        resp = await _dio.get('/attendance/organization-status', queryParameters: {'date': date});
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          resp = await _dio.get('/attendance/all', queryParameters: {'date': date});
        } else {
          rethrow;
        }
      }

      if (resp.statusCode == 200) {
        final data = resp.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['attendance'] ?? data['records'] ?? data['data'] ?? [];
        }
        final list = rawList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (!map.containsKey('status') || map['status'] == null) {
            map['status'] = (map['isPresent'] == true) ? 'Present' : 'Absent';
          }
          return map;
        }).toList();

        final filteredList = list.where((item) {
          if (item.containsKey('date') && item['date'] != null) {
            return item['date'].toString().startsWith(date);
          }
          return true;
        }).toList();

        return ApiSuccess(filteredList);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to get attendance'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getUserAttendance(String userId, {int page = 1, int pageSize = 100}) async {
    try {
      final resp = await _dio.get('/attendance/all', queryParameters: {
        'userId': userId,
        'page': page,
        'pageSize': pageSize,
      });
      if (resp.statusCode == 200) {
        final data = resp.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['attendance'] ?? data['records'] ?? data['data'] ?? [];
        }
        final list = rawList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (!map.containsKey('status') || map['status'] == null) {
            map['status'] = (map['isPresent'] == true) ? 'Present' : 'Absent';
          }
          return map;
        }).toList();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to get user attendance'));
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
