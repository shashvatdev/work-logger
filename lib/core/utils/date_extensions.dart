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
