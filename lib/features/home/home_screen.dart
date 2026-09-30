import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';
import '../../data/models/models.dart';
import '../attendance/presentation/widgets/punch_card_widget.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myProjectsAsync = ref.watch(myProjectsProvider);
    final todayLogAsync = ref.watch(todayLogProvider);
    final today = DateTime.now();

    if (user == null) return const SizedBox.shrink();

    if (myProjectsAsync.hasError || todayLogAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: Center(
          child: Text('Failed to load data. Pull to refresh.', 
            style: TextStyle(color: AppColors.error)),
        ),
      );
    }

    if (myProjectsAsync.isLoading || todayLogAsync.isLoading) {
      if (!myProjectsAsync.hasValue && !todayLogAsync.hasValue) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    4,
                    (index) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: SkeletonRow(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    final myProjects = myProjectsAsync.valueOrNull ?? <ProjectModel>[];
    final todayLog = todayLogAsync.valueOrNull;

    final hasTodayLog = todayLog != null && todayLog.entries.isNotEmpty;

    final isProjectTechLead = myProjects.any((p) => p.techLeads.any((tl) => tl.id == user.id));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myProjectsProvider);
            ref.invalidate(todayLogProvider);
            ref.invalidate(allUsersProvider);
            ref.invalidate(allProjectsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Large Title App Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          today.greeting,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                        Text(
                          user.name.split(' ').first,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              today.displayDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                            ),
                            if (isProjectTechLead) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  'Tech Lead',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    _TopActions(user: user),
                  ],
                ),
              ),
            ),

            // ── Attendance Punch Card (Hidden for SuperAdmin) ────────────
            if (!user.isSuperAdmin)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, AppSpacing.sm, 0, AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attendance',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary(context),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/attendance'),
                              child: Text(
                                'View History',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PunchCardWidget(),
                    ],
                  ),
                ),
              ),



            // ── "Today's Log" status ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                    AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  children: [
                    Text(
                      'Today',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (hasTodayLog)
                      AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'Logged today',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Projects List ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: myProjects.isEmpty
                    ? _EmptyProjects()
                    : SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < myProjects.length; i++) ...[
                              StaggeredItem(
                                index: i,
                                child: _ProjectRow(
                                  project: myProjects[i],
                                  onTap: () {
                                    context.push('/log/${today.logKey}?projectId=${myProjects[i].id}');
                                  },
                                ),
                              ),
                              if (i < myProjects.length - 1)
                                const AppDivider(indent: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),

      // ── Bottom CTA ─────────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
              AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumButton(
                label: hasTodayLog ? 'Edit Today\'s Log' : 'Log Today\'s Work',
                icon: hasTodayLog
                    ? Icons.edit_outlined
                    : Icons.add_rounded,
                onPressed: () => context.push('/log/${today.logKey}'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.calendar_today_outlined,
                    label: 'Calendar',
                    onTap: () => context.push('/calendar'),
                  ),
                  if (user.isAdmin)
                    _NavButton(
                      icon: Icons.groups_rounded,
                      label: 'Team Logs',
                      onTap: () => context.push('/team-logs'),
                    )
                  else if (isProjectTechLead)
                    _NavButton(
                      icon: Icons.folder_open_outlined,
                      label: 'Projects',
                      onTap: () => context.push('/tech-lead/projects'),
                    ),
                  _NavButton(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onTap: () => context.push('/search'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActions extends ConsumerWidget {
  final dynamic user;
  const _TopActions({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Builder(
          builder: (scaffoldContext) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Scaffold.of(scaffoldContext).openDrawer();
            },
            child: InitialsAvatar(name: user.name, radius: 20, showRing: true),
          ),
        ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final dynamic project;
  final VoidCallback onTap;
  const _ProjectRow({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLead = project.techLeads.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              color: AppColors.projectColor(project.id),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (hasLead) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.stars_rounded, size: 12, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Leads: ${project.techLeads.map((e) => e.name).join(', ')}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accent),
                      tooltip: 'Project details',
                      onPressed: () => context.push('/projects/${project.id}'),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textTertiary(context),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: EmptyStateWidget(
        icon: Icons.work_outline,
        title: 'No projects assigned',
        subtitle: 'Your admin will assign you to projects.',
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadowLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
