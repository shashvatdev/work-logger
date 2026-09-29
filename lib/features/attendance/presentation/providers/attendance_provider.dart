import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/datasource/attendance_api_service.dart';
import '../../data/models/attendance_status.dart';
import '../../data/models/calendar_day.dart';

// ── Uses the app's shared ApiClient (which already handles token via AuthInterceptor)
// ── attendanceStatusProvider only fetches when user is logged in
final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService(ApiClient.instance);
});

final attendanceStatusProvider = FutureProvider.autoDispose<AttendanceStatus>((ref) async {
  // Gate: only call API when user is authenticated
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');
  
  final apiService = ref.watch(attendanceApiServiceProvider);
  return apiService.getStatus();
});

final attendanceCalendarProvider =
    FutureProvider.family.autoDispose<List<CalendarDay>, ({String from, String to})>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');
  
  final apiService = ref.watch(attendanceApiServiceProvider);
  return apiService.getCalendar(params.from, params.to);
});
