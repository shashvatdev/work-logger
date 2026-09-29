import 'assigned_office.dart';
import 'today_record.dart';

class AttendanceStatus {
  final bool isPunchedIn;
  final bool isCompletedForToday;
  final AssignedOffice? assignedOffice;
  final TodayRecord? todayRecord;

  AttendanceStatus({
    required this.isPunchedIn,
    required this.isCompletedForToday,
    this.assignedOffice,
    this.todayRecord,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceStatus(
      isPunchedIn: json['isPunchedIn'] as bool? ?? false,
      isCompletedForToday: json['isCompletedForToday'] as bool? ?? false,
      assignedOffice: json['assignedOffice'] != null ? AssignedOffice.fromJson(json['assignedOffice']) : null,
      todayRecord: json['todayRecord'] != null ? TodayRecord.fromJson(json['todayRecord']) : null,
    );
  }
}
