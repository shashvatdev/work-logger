import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final String? viewUserId;
  const CalendarScreen({super.key, this.viewUserId});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final targetUid = widget.viewUserId ?? currentUser?.id ?? '';
    final datesWithLogsAsync = ref.watch(datesWithLogsProvider((
      uid: targetUid,
      year: _focusedMonth.year,
      month: _focusedMonth.month,
    )));
    final datesWithLogs = datesWithLogsAsync.valueOrNull ?? <String>{};

    final targetUser = ref.watch(allUsersProvider).valueOrNull
        ?.where((u) => u.id == targetUid)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final user = ref.read(currentUserProvider);
              if (user?.isAdmin == true) {
                context.go('/admin/employees');
              } else {
                context.go('/home');
              }
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.viewUserId != null && targetUser != null) ...[
                  InitialsAvatar(name: targetUser.name, radius: 14, showRing: true),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  widget.viewUserId != null
                      ? targetUser?.name ?? 'Calendar'
                      : 'Calendar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            if (widget.viewUserId != null && targetUser != null)
              Text(
                'Work history',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
              ),
          ],
        ),

      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Month navigation ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.accent,
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month - 1);
                    }),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0.2, 0.0),
                          end: Offset.zero,
                        ).animate(animation);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _focusedMonth.monthYear,
                        key: ValueKey<String>(_focusedMonth.monthYear),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.accent,
                    onPressed: () {
                      final now = DateTime.now();
                      final nextMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month + 1);
                      if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                        setState(() => _focusedMonth = nextMonth);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Day of week labels ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                    .asMap().entries.map((entry) => Expanded(
                          child: Center(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: entry.key == 6 ? AppColors.accent : AppColors.textSecondaryLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Calendar Grid ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: datesWithLogsAsync.hasError
                    ? Center(
                        child: Text(
                          'Failed to load calendar data.',
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : _CalendarGrid(
                        focusedMonth: _focusedMonth,
                        datesWithLogs: datesWithLogs,
                        targetUid: targetUid,
                        onDateTap: (date) {
                          if (date.isAfterToday) return;
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          if (widget.viewUserId != null) {
                            context.push('/log/$dateStr?viewUserId=${widget.viewUserId}');
                          } else {
                            context.push('/log/$dateStr');
                          }
                        },
                ),
              ),
            ),

            // ── Legend ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                      color: AppColors.logDot, label: 'Log exists'),
                  const SizedBox(width: AppSpacing.lg),
                  _LegendItem(
                      color: AppColors.accent,
                      label: 'Today',
                      isBorder: true),
                  const SizedBox(width: AppSpacing.lg),
                  _LegendItem(
                      color: AppColors.dotEmpty,
                      label: 'No log'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<String> datesWithLogs;
  final String targetUid;
  final ValueChanged<DateTime> onDateTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.datesWithLogs,
    required this.targetUid,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // 0 = Sunday

    final cells = <DateTime?>[
      ...List.filled(startOffset, null),
      for (int d = 1; d <= daysInMonth; d++)
        DateTime(focusedMonth.year, focusedMonth.month, d),
    ];

    // Pad to full weeks
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final date = cells[index];
        if (date == null) return const SizedBox.shrink();
        return _CalendarCell(
          date: date,
          hasLog: datesWithLogs.contains(
              DateFormat('yyyy-MM-dd').format(date)),
          onTap: () => onDateTap(date),
        );
      },
    );
  }
}

class _CalendarCell extends StatefulWidget {
  final DateTime date;
  final bool hasLog;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.date,
    required this.hasLog,
    required this.onTap,
  });

  @override
  State<_CalendarCell> createState() => _CalendarCellState();
}

class _CalendarCellState extends State<_CalendarCell> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.date.isToday;
    final isFuture = widget.date.isAfterToday;

    return GestureDetector(
      onTapDown: isFuture ? null : (_) => _anim.forward(),
      onTapUp: isFuture ? null : (_) { _anim.reverse(); widget.onTap(); },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.92).animate(_anim),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isToday ? AppColors.accentGradient : null,
          ),
          child: Opacity(
            opacity: isFuture ? 0.3 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday
                            ? Colors.white
                            : AppColors.textPrimary(context),
                      ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.hasLog ? 7 : 5,
                  height: widget.hasLog ? 7 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.hasLog
                        ? (isToday ? Colors.white : AppColors.success)
                        : Colors.transparent,
                    boxShadow: widget.hasLog && !isToday ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 4)] : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isBorder;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBorder ? Colors.transparent : color,
              border: isBorder ? Border.all(color: color, width: 2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
