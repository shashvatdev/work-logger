import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/admin_providers.dart';
import 'regularize_modal.dart';
import 'user_attendance_history_screen.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attendanceAsync = ref.watch(allAttendanceDateProvider(dateStr));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('All Attendance'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SecondaryButton(
                  label: 'Change Date',
                  icon: Icons.calendar_today,
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allAttendanceDateProvider(dateStr));
              },
              child: attendanceAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        EmptyStateWidget(
                          icon: Icons.event_busy,
                          title: 'No Records',
                          subtitle: 'No attendance records found for this date.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final name = record['userName'] ?? 'Unknown';
                      final punchIn = record['punchInTime'];
                      final punchOut = record['punchOutTime'];
                      final status = record['status'] ?? 'Absent';
                      final userId = record['userId'] ?? '';

                      String formatTimeStr(String? isoString) {
                        if (isoString == null || isoString.isEmpty) return '--:--';
                        try {
                          final dt = DateTime.parse(isoString).toLocal();
                          return DateFormat('hh:mm a').format(dt);
                        } catch (_) {
                          return isoString;
                        }
                      }

                      final punchInStr = formatTimeStr(punchIn);
                      final punchOutStr = formatTimeStr(punchOut);

                      return SurfaceCard(
                        child: InkWell(
                          onTap: userId.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserAttendanceHistoryScreen(
                                        userId: userId,
                                        userName: name,
                                        userEmail: record['userEmail'] as String?,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: Row(
                            children: [
                              InitialsAvatar(
                                name: name,
                                radius: AppSpacing.avatarLg,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'In: $punchInStr • Out: $punchOutStr',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary(context),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ChipLabel(
                                    label: status,
                                    color: status == 'Present' ? AppColors.success : AppColors.error,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => RegularizeModal(
                                          userId: userId,
                                          userName: name,
                                          dateStr: dateStr,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                      child: Text(
                                        'Regularize',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, __) => const SkeletonRow(),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
