import 'package:dio/dio.dart';
import '../models/attendance_status.dart';
import '../models/calendar_day.dart';

/// Uses the shared ApiClient Dio instance — no separate base URL needed
/// since ApiClient already sets the correct base URL and auth token.
class AttendanceApiService {
  final Dio _dio;

  AttendanceApiService(this._dio);

  Future<AttendanceStatus> getStatus() async {
    final response = await _dio.get('/attendance/status');
    return AttendanceStatus.fromJson(response.data);
  }

  Future<void> punchIn(double lat, double lng, {String? remarks}) async {
    try {
      final response = await _dio.post('/attendance/punch-in', data: {
        'latitude': lat,
        'longitude': lng,
        if (remarks != null) 'remarks': remarks,
      });

      _validateResponse(response, defaultError: 'Failed to punch in.');
    } on DioException catch (e) {
      final msg = _extractMessageFromData(e.response?.data) ??
          e.message ??
          'Failed to punch in. Please check your internet connection.';
      throw Exception(msg);
    }
  }

  Future<void> punchOut(double lat, double lng, {String? remarks}) async {
    try {
      final response = await _dio.post('/attendance/punch-out', data: {
        'latitude': lat,
        'longitude': lng,
        if (remarks != null) 'remarks': remarks,
      });

      _validateResponse(response, defaultError: 'Failed to punch out.');
    } on DioException catch (e) {
      final msg = _extractMessageFromData(e.response?.data) ??
          e.message ??
          'Failed to punch out. Please check your internet connection.';
      throw Exception(msg);
    }
  }

  Future<List<CalendarDay>> getCalendar(String from, String to) async {
    final response = await _dio.get('/attendance/calendar',
        queryParameters: {'from': from, 'to': to});

    final list = response.data['calendar'] as List?;
    if (list == null) return [];
    return list.map((e) => CalendarDay.fromJson(e)).toList();
  }

  void _validateResponse(Response response, {required String defaultError}) {
    if (response.statusCode != null &&
        (response.statusCode! < 200 || response.statusCode! >= 300)) {
      final msg = _extractMessageFromData(response.data) ??
          'Error (${response.statusCode}): $defaultError';
      throw Exception(msg);
    }

    final data = response.data;
    if (data is Map) {
      if (data['success'] == false || data['isSuccess'] == false) {
        final msg = _extractMessageFromData(data) ?? defaultError;
        throw Exception(msg);
      }
    }
  }

  /// Extracts the human-readable error message from backend response data.
  String? _extractMessageFromData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      // 1. Direct message / error / detail keys
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
        return data['error'].toString();
      }
      if (data['detail'] != null && data['detail'].toString().trim().isNotEmpty) {
        return data['detail'].toString();
      }

      // 2. Validation errors (FluentValidation / ASP.NET / ModelState)
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.join('\n');
        }
        if (errors is Map && errors.isNotEmpty) {
          final messages = <String>[];
          for (final val in errors.values) {
            if (val is List) {
              messages.addAll(val.map((e) => e.toString()));
            } else if (val != null) {
              messages.add(val.toString());
            }
          }
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }

      if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
        return data['title'].toString();
      }

      // If map is non-empty but has custom keys, return whole body as string
      return data.toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return data.toString();
  }
}
