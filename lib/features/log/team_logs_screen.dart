import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';

class TeamLogsScreen extends ConsumerStatefulWidget {
  const TeamLogsScreen({super.key});

  @override
  ConsumerState<TeamLogsScreen> createState() => _TeamLogsScreenState();
}

class _TeamLogsScreenState extends ConsumerState<TeamLogsScreen> {
  final _scrollController = ScrollController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamLogsProvider.notifier).load(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(teamLogsProvider.notifier).load();
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: (_fromDate != null && _toDate != null)
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _applyFilter();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final fmt = DateFormat('yyyy-MM-dd');
    ref.read(teamLogsProvider.notifier).applyFilters(
          from: _fromDate != null ? fmt.format(_fromDate!) : null,
          to: _toDate != null ? fmt.format(_toDate!) : null,
          employeeId: _selectedEmployeeId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final teamLogsState = ref.watch(teamLogsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final allUsers = usersAsync.valueOrNull ?? <UserModel>[];
    final employees = allUsers.where((u) => !u.isAdmin).toList();

    final fmt = DateFormat('d MMM');
    final hasDateFilter = _fromDate != null || _toDate != null;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Team Work Logs', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(teamLogsProvider.notifier).load(reset: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filters Bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Date range picker chip
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: hasDateFilter
                                  ? AppColors.accent.withOpacity(0.12)
                                  : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: hasDateFilter
                                    ? AppColors.accent.withOpacity(0.4)
                                    : AppColors.separator(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: hasDateFilter ? AppColors.accent : AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasDateFilter
                                        ? '${fmt.format(_fromDate!)} - ${fmt.format(_toDate!)}'
                                        : 'Filter by Date Range',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: hasDateFilter ? AppColors.accent : AppColors.textSecondary(context),
                                          fontWeight: hasDateFilter ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasDateFilter)
                                  GestureDetector(
                                    onTap: _clearDateFilter,
                                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.accent),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Employee dropdown filter
                      if (employees.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedEmployeeId != null
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: _selectedEmployeeId != null
                                  ? AppColors.accent.withOpacity(0.4)
                                  : AppColors.separator(context),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedEmployeeId,
                              hint: Text(
                                'All Members',
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                              icon: Icon(
                                Icons.filter_list_rounded,
                                size: 16,
                                color: _selectedEmployeeId != null ? AppColors.accent : AppColors.textSecondary(context),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Members', style: TextStyle(fontSize: 12)),
                                ),
                                ...employees.map((e) => DropdownMenuItem<String?>(
                                      value: e.id,
                                      child: Text(e.name, style: const TextStyle(fontSize: 12)),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedEmployeeId = val);
                                _applyFilter();
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Logs List ────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(teamLogsProvider.notifier).load(reset: true);
                },
                child: teamLogsState.isLoading && teamLogsState.logs.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: List.generate(
                          5,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm),
                            child: SkeletonRow(),
                          ),
                        ),
                      )
                    : teamLogsState.logs.isEmpty
                        ? const Center(
                            child: EmptyStateWidget(
                              icon: Icons.history_rounded,
                              title: 'No team logs found',
                              subtitle: 'No updates recorded for the selected filter.',
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: teamLogsState.logs.length + (teamLogsState.hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              if (index >= teamLogsState.logs.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              }

                              final logData = teamLogsState.logs[index];
                              return _TeamLogCard(logData: logData);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add My Daily Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () {
          final today = DateTime.now();
          final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          context.push('/log/$key');
        },
      ),
    );
  }
}

class _TeamLogCard extends StatelessWidget {
  final Map<String, dynamic> logData;
  const _TeamLogCard({required this.logData});

  @override
  Widget build(BuildContext context) {
    final dateStr = logData['logDate'] ?? logData['date'] ?? '';
    final userName = logData['userName'] ?? logData['user']?['name'] ?? 'Team Member';
    final entries = (logData['entries'] as List? ?? []);
    final entryCount = logData['entryCount'] as int? ?? entries.length;

    String dateDisplay = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      dateDisplay = DateFormat('EEE, d MMM yyyy').format(parsed);
    } catch (_) {}

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: userName, radius: 16, showRing: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      dateDisplay,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$entryCount ${entryCount == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const AppDivider(),
            const SizedBox(height: 8),
            for (final entry in entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry['projectName'] != null && entry['projectName'].toString().isNotEmpty)
                            Text(
                              entry['projectName'].toString(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          Text(
                            entry['description']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
