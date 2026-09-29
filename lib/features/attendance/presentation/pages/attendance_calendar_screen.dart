import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/attendance_provider.dart';
import '../../data/models/calendar_day.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  String get _from =>
      DateFormat('yyyy-MM-dd').format(_selectedMonth);

  String get _to => DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

  void _prevMonth() =>
      setState(() => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() => _selectedMonth = next);
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(
      attendanceCalendarProvider((from: _from, to: _to)),
    );

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  const BackChevron(label: 'Back'),
                  const Spacer(),
                  Text(
                    'Attendance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  // Invisible to center title
                  const SizedBox(width: 72),
                ],
              ),
            ),

            // ── Month Picker ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MonthNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _prevMonth,
                    enabled: true,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  _MonthNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                    enabled: _canGoNext,
                  ),
                ],
              ),
            ),

            // ── Summary Bar ──────────────────────────────────────────────────
            calendarAsync.when(
              data: (days) => _SummaryBar(days: days),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: calendarAsync.when(
                loading: () => _buildSkeletonList(),
                error: (e, _) => _buildError(context, e),
                data: (days) {
                  if (days.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.calendar_month_outlined,
                      title: 'No records this month',
                      subtitle: 'Attendance logs will appear here.',
                    );
                  }
                  // Sort descending (latest first)
                  final sorted = [...days]
                    ..sort((a, b) => b.date.compareTo(a.date));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => _DayRow(
                      day: sorted[i],
                      isLast: i == sorted.length - 1,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) => Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SkeletonLoader(width: 40, height: 40, borderRadius: 10),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonLoader(width: 100, height: 12, borderRadius: 6),
                  const SizedBox(height: 6),
                  SkeletonLoader(width: 160, height: 10, borderRadius: 5),
                ],
              ),
            ),
            SkeletonLoader(width: 60, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text('Failed to load attendance',
                style: TextStyle(color: AppColors.error,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(attendanceCalendarProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Monthly summary — Present / Incomplete / Absent counts
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final List<CalendarDay> days;
  const _SummaryBar({required this.days});

  @override
  Widget build(BuildContext context) {
    final present = days.where((d) => d.status == 'Present').length;
    final incomplete = days.where((d) => d.status == 'Incomplete').length;
    final absent = days.where((d) => d.status == 'Absent').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
              child: _SummaryTile(
                  label: 'Present',
                  count: present,
                  color: AppColors.success)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _SummaryTile(
                  label: 'Incomplete',
                  count: incomplete,
                  color: AppColors.warning)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _SummaryTile(
                  label: 'Absent',
                  count: absent,
                  color: AppColors.error)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryTile(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.18), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Single day row card
// ─────────────────────────────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final CalendarDay day;
  final bool isLast;
  const _DayRow({required this.day, required this.isLast});

  Color get _statusColor {
    switch (day.status) {
      case 'Present':
        return AppColors.success;
      case 'Incomplete':
        return AppColors.warning;
      case 'Absent':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  IconData get _statusIcon {
    switch (day.status) {
      case 'Present':
        return Icons.check_circle_rounded;
      case 'Incomplete':
        return Icons.warning_amber_rounded;
      case 'Absent':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final date = DateTime.tryParse(day.date) ?? DateTime.now();
    final dayName = DateFormat('EEE').format(date); // Mon, Tue
    final dayNum = DateFormat('d').format(date);    // 1, 15, 28

    final inTime = day.punchInTime != null
        ? DateFormat('hh:mm a').format(day.punchInTime!)
        : null;
    final outTime = day.punchOutTime != null
        ? DateFormat('hh:mm a').format(day.punchOutTime!)
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: AppColors.isDark(context)
              ? Border.all(
                  color: AppColors.separatorDark.withOpacity(0.4),
                  width: 0.5)
              : null,
          boxShadow: AppColors.isDark(context) ? null : AppColors.cardShadowLight,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Date badge ────────────────────────────────────────────────
              Container(
                width: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppSpacing.radiusMd)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNum,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              color: color, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      dayName.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),

              // ── Times ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (inTime != null || outTime != null)
                        Row(
                          children: [
                            if (inTime != null) ...[
                              Icon(Icons.login_rounded,
                                  size: 12,
                                  color: AppColors.success),
                              const SizedBox(width: 3),
                              Text(inTime,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                            ],
                            if (inTime != null && outTime != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 11,
                                    color: AppColors.textTertiary(context)),
                              ),
                            if (outTime != null) ...[
                              Icon(Icons.logout_rounded,
                                  size: 12, color: AppColors.error),
                              const SizedBox(width: 3),
                              Text(outTime,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                            ],
                          ],
                        )
                      else
                        Text(
                          day.status == 'Absent'
                              ? 'No attendance record'
                              : 'No data',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: AppColors.textTertiary(context)),
                        ),
                      if (day.workingTimeFormatted != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 11,
                                color: AppColors.textSecondary(context)),
                            const SizedBox(width: 3),
                            Text(
                              day.workingTimeFormatted!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color:
                                          AppColors.textSecondary(context)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Status badge ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_statusIcon, color: color, size: 18),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        day.status,
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Month navigation arrow button
// ─────────────────────────────────────────────────────────────────────────────
class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _MonthNavButton(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.accentMid
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.accent
              : AppColors.textTertiary(context),
          size: 22,
        ),
      ),
    );
  }
}
