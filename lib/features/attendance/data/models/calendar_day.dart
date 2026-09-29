import '../../../../core/utils/date_extensions.dart';

class CalendarDay {
  final String date;
  final String status;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final double? totalWorkingHours;
  final String? workingTimeFormatted;
  final bool hasDailyLog;

  CalendarDay({
    required this.date,
    required this.status,
    this.punchInTime,
    this.punchOutTime,
    this.totalWorkingHours,
    this.workingTimeFormatted,
    required this.hasDailyLog,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] as String,
      status: json['status'] as String,
      punchInTime: parseBackendTime(json['punchInTime']),
      punchOutTime: parseBackendTime(json['punchOutTime']),
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble(),
      workingTimeFormatted: json['workingTimeFormatted'] as String?,
      hasDailyLog: json['hasDailyLog'] as bool? ?? false,
    );
  }
}
