import '../../../../core/utils/date_extensions.dart';

class TodayRecord {
  final String id;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final double? totalWorkingHours;
  final String? workingTimeFormatted;
  final String status;

  TodayRecord({
    required this.id,
    this.punchInTime,
    this.punchOutTime,
    this.totalWorkingHours,
    this.workingTimeFormatted,
    required this.status,
  });

  factory TodayRecord.fromJson(Map<String, dynamic> json) {
    return TodayRecord(
      id: json['id'] as String,
      punchInTime: parseBackendTime(json['punchInTime']),
      punchOutTime: parseBackendTime(json['punchOutTime']),
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble(),
      workingTimeFormatted: json['workingTimeFormatted'] as String?,
      status: json['status'] as String? ?? 'Incomplete',
    );
  }
}
