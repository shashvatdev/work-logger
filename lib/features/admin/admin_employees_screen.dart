import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';

class AdminEmployeesScreen extends ConsumerWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(e.toString())),
      data: (allUsers) {
        final employees = allUsers.where((u) => !u.isAdmin).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${employees.length} members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () async {
                            await AuthRepository().logout();
                            ref.read(currentUserProvider.notifier).state = null;
                            ref.invalidate(allUsersProvider);
                            ref.invalidate(allProjectsProvider);
                            ref.invalidate(myProjectsProvider);
                            ref.invalidate(todayLogProvider);
                            ref.invalidate(yesterdayLogProvider);
                          },
                          child: InitialsAvatar(
                              name: user?.name ?? 'Admin', radius: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TodayStatusSummary(employees: employees),
                  ],
                ),
              ),
            ),

            // ── Section label ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                child: Text(
                  'ALL MEMBERS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ),
            ),

            // ── Employees list ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < employees.length; i++) ...[
                        _EmployeeRow(employee: employees[i]),
                        if (i < employees.length - 1)
                          const AppDivider(indent: 72),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }
}

class _TodayStatusSummary extends ConsumerWidget {
  final List<UserModel> employees;
  const _TodayStatusSummary({required this.employees});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int updatedCount = 0;
    for (final e in employees) {
      if (ref.watch(employeeTodayStatusProvider(e.id)).valueOrNull == true) {
        updatedCount++;
      }
    }
    final notUpdated = employees.length - updatedCount;

    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$updatedCount',
              label: 'Updated Today',
              color: AppColors.logDot,
            ),
          ),
          Container(
            width: 0.5,
            height: 36,
            color: AppColors.separator(context),
          ),
          Expanded(
            child: _StatCell(
              value: '$notUpdated',
              label: 'No Update',
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w300,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary(context),
              ),
        ),
      ],
    );
  }
}

class _EmployeeRow extends ConsumerWidget {
  final UserModel employee;
  const _EmployeeRow({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(employeeTodayStatusProvider(employee.id));
    final updated = statusAsync.valueOrNull ?? false;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      leading: InitialsAvatar(name: employee.name, radius: 20),
      title: Text(employee.name,
          style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Row(
        children: [
          if (statusAsync.isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            StatusDot(active: updated, size: 7),
            const SizedBox(width: 6),
            Text(
              updated ? 'Updated Today' : 'No Update',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: updated
                        ? AppColors.logDot
                        : AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
            ),
          ],
        ],
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary(context), size: 20),
      onTap: () => context
          .push('/admin/employees/${employee.id}/calendar'),
    );
  }
}
