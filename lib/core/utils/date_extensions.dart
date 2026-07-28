import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get displayDate => DateFormat('EEEE, MMMM d').format(this);
  String get shortDate => DateFormat('d MMM').format(this);
  String get logKey => DateFormat('yyyy-MM-dd').format(this);
  String get monthYear => DateFormat('MMMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isBeforeToday {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final thisOnly = DateTime(year, month, day);
    return thisOnly.isBefore(todayOnly);
  }

  bool get isAfterToday {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final thisOnly = DateTime(year, month, day);
    return thisOnly.isAfter(todayOnly);
  }

  DateTime get dateOnly => DateTime(year, month, day);

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

extension StringBulletExtensions on String {
  /// Formats bullet points with clean spacing between items
  String get withBulletSpacing {
    if (!contains('\n')) return this;
    return replaceAll(RegExp(r'\n+(?=[•\-])'), '\n\n');
  }
}

/// Parses time strings like "2h 23m", "45m", "1.5h", "2h 23m, 1h 30m" to total minutes
double parseTimeToMinutes(String raw) {
  if (raw.trim().isEmpty) return 0;
  double totalMins = 0;

  final matches = RegExp(r'(\d+(?:\.\d+)?)\s*([hm])?|\b(\d+(?:\.\d+)?)\b', caseSensitive: false)
      .allMatches(raw);

  for (final m in matches) {
    final strVal = m.group(1) ?? m.group(3);
    if (strVal == null) continue;
    final val = double.tryParse(strVal);
    if (val == null) continue;

    final unit = m.group(2)?.toLowerCase();
    if (unit == 'h') {
      totalMins += val * 60;
    } else if (unit == 'm') {
      totalMins += val;
    } else {
      totalMins += val * 60;
    }
  }

  return totalMins;
}

/// Formats total minutes to clean string like "3h 53m", "45m", "2h"
String formatMinutesToDisplay(double totalMins) {
  if (totalMins <= 0) return '';
  final totalMinsInt = totalMins.round();
  final hours = totalMinsInt ~/ 60;
  final mins = totalMinsInt % 60;

  if (hours > 0 && mins > 0) {
    return '${hours}h ${mins}m';
  } else if (hours > 0) {
    return '${hours}h';
  } else {
    return '${mins}m';
  }
}

/// Parses and formats any raw time string to combined display string (e.g. "2h 23m, 1h 30m" -> "3h 53m")
String formatTotalTimeString(String rawTime) {
  final mins = parseTimeToMinutes(rawTime);
  if (mins <= 0) return rawTime;
  return formatMinutesToDisplay(mins);
}
