import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/calendar_screen.dart';

class AdminEmployeeCalendarScreen extends ConsumerWidget {
  final String userId;
  const AdminEmployeeCalendarScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CalendarScreen(viewUserId: userId);
  }
}
