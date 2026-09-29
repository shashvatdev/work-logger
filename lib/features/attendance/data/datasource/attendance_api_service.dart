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
      await _dio.post('/attendance/punch-in', data: {
        'latitude': lat,
        'longitude': lng,
        if (remarks != null) 'remarks': remarks,
      });
    } on DioException catch (e) {
      final msg = _extractMessage(e) ?? 'Outside assigned office geofence.';
      throw Exception(msg);
    }
  }

  Future<void> punchOut(double lat, double lng, {String? remarks}) async {
    try {
      await _dio.post('/attendance/punch-out', data: {
        'latitude': lat,
        'longitude': lng,
        if (remarks != null) 'remarks': remarks,
      });
    } on DioException catch (e) {
      final msg = _extractMessage(e) ?? 'Outside assigned office geofence.';
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

  /// Extracts the human-readable error message from a DioException response.
  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['error'] as String?;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
