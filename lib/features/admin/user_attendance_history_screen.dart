import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/admin_providers.dart';
import 'regularize_modal.dart';

class UserAttendanceHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? userEmail;

  const UserAttendanceHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userEmail,
  });

  @override
  ConsumerState<UserAttendanceHistoryScreen> createState() =>
      _UserAttendanceHistoryScreenState();
}

class _UserAttendanceHistoryScreenState
    extends ConsumerState<UserAttendanceHistoryScreen> {
  String _selectedMonthKey = 'ALL';

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _formatDate(String? dateStr, String? createdAt) {
    final raw = dateStr ?? createdAt;
    if (raw == null || raw.isEmpty) return 'Unknown Date';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _getMonthKey(String? dateStr, String? createdAt) {
    final raw = dateStr ?? createdAt;
    if (raw == null || raw.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM').format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  String _formatMonthLabel(String monthKey) {
    if (monthKey == 'ALL') return 'All Months';
    try {
      final parts = monthKey.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return monthKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(userAttendanceHistoryProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
              Text(
                widget.userEmail!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userAttendanceHistoryProvider(widget.userId));
        },
        child: historyAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'No Attendance Records',
                    subtitle: 'No attendance history found for this user.',
                  ),
                ],
              );
            }

            // Extract unique months for filter
            final monthsSet = <String>{};
            for (final r in records) {
              final mk = _getMonthKey(r['date'], r['createdAt']);
              if (mk != 'Unknown') monthsSet.add(mk);
            }
            final sortedMonths = monthsSet.toList()..sort((a, b) => b.compareTo(a));

            // Filter records by selected month
            final filteredRecords = _selectedMonthKey == 'ALL'
                ? records
                : records.where((r) {
                    return _getMonthKey(r['date'], r['createdAt']) ==
                        _selectedMonthKey;
                  }).toList();

            // Calculate stats
            double totalHours = 0;
            int presentCount = filteredRecords.length;
            for (final r in filteredRecords) {
              final hrs = r['totalWorkingHours'];
              if (hrs is num) {
                totalHours += hrs.toDouble();
              }
            }
            final avgHours = presentCount > 0 ? (totalHours / presentCount) : 0.0;

            return Column(
              children: [
                // Month selector chips
                if (sortedMonths.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedMonthKey == 'ALL',
                          onSelected: (val) {
                            if (val) setState(() => _selectedMonthKey = 'ALL');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ...sortedMonths.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: ChoiceChip(
                              label: Text(_formatMonthLabel(m)),
                              selected: _selectedMonthKey == m,
                              onSelected: (val) {
                                if (val) setState(() => _selectedMonthKey = m);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                // Stats Bar (Present Days | Total Hours | Avg/Day)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Present Days',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '$presentCount',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Hours',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${totalHours.toStringAsFixed(1)}h',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Avg / Day',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${avgHours.toStringAsFixed(1)}h',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Records list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                    itemCount: filteredRecords.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      final dateFormatted =
                          _formatDate(record['date'], record['createdAt']);
                      final punchIn = _formatTime(record['punchInTime']);
                      final punchOut = _formatTime(record['punchOutTime']);
                      final status = record['status'] ??
                          (record['isPresent'] == true ? 'Present' : 'Absent');
                      final isPresent = status == 'Present';
                      final workingFormatted = record['workingTimeFormatted'] ??
                          '${(record['totalWorkingHours'] as num?)?.toStringAsFixed(1) ?? '0'}h';
                      final locationName = record['punchInLocationName'] ??
                          record['punchOutLocationName'];
                      final remarks = record['remarks'] as String?;
                      final recordDateStr = (record['date'] ??
                              record['createdAt'] ??
                              '')
                          .toString()
                          .split('T')
                          .first;

                      return SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      dateFormatted,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                ChipLabel(
                                  label: status,
                                  color: isPresent
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Punch In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary(
                                                  context)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      punchIn,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Punch Out',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary(
                                                  context)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      punchOut,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Working Hours',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary(
                                                  context)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      workingFormatted,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accent,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (locationName != null && locationName.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    locationName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary(
                                                context)),
                                  ),
                                ],
                              ),
                            ],
                            if (remarks != null && remarks.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.elevated(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 13,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        remarks,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              color: AppColors.textSecondary(context),
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => RegularizeModal(
                                      userId: widget.userId,
                                      userName: widget.userName,
                                      dateStr: recordDateStr,
                                    ),
                                  ).then((_) {
                                    ref.invalidate(userAttendanceHistoryProvider(
                                        widget.userId));
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 2),
                                  child: Text(
                                    'Regularize',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, __) => const SkeletonRow(),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
