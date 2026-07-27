import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myProjectsAsync = ref.watch(myProjectsProvider);
    final todayLogAsync = ref.watch(todayLogProvider);
    final yesterdayLogAsync = ref.watch(yesterdayLogProvider);
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

    if (myProjectsAsync.isLoading || todayLogAsync.isLoading || yesterdayLogAsync.isLoading) {
      if (!myProjectsAsync.hasValue && !todayLogAsync.hasValue) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    final myProjects = myProjectsAsync.valueOrNull ?? <ProjectModel>[];
    final todayLog = todayLogAsync.valueOrNull;
    final yesterdayLog = yesterdayLogAsync.valueOrNull;

    final hasYesterdayLog = yesterdayLog != null && yesterdayLog.entries.isNotEmpty;
    final hasTodayLog = todayLog != null && todayLog.entries.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myProjectsProvider);
            ref.invalidate(todayLogProvider);
            ref.invalidate(yesterdayLogProvider);
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
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today.displayDate,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                        ),
                      ],
                    ),
                    _TopActions(user: user),
                  ],
                ),
              ),
            ),

            // ── "Continue Yesterday" banner ──────────────────────────────────
            if (hasYesterdayLog && !hasTodayLog)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: _ContinueYesterdayBanner(
                    onTap: () {
                      context.push(
                          '/log/${today.logKey}?continueYesterday=true');
                    },
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
                      ChipLabel(
                        label: 'Logged',
                        color: AppColors.logDot,
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
                              _ProjectRow(
                                project: myProjects[i],
                                onTap: () {
                                  context.push('/log/${today.logKey}?projectId=${myProjects[i].id}');
                                },
                              ),
                              if (i < myProjects.length - 1)
                                const AppDivider(indent: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
              ),
            ),

            const SliverFillRemaining(hasScrollBody: false),
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
        GestureDetector(
          onTap: () async {
            await AuthRepository().logout();
            ref.read(currentUserProvider.notifier).state = null;
            ref.invalidate(allProjectsProvider);
            ref.invalidate(myProjectsProvider);
            ref.invalidate(todayLogProvider);
            ref.invalidate(yesterdayLogProvider);
          },
          child: InitialsAvatar(name: user.name, radius: 20),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      title: Text(
        project.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary(context),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _ContinueYesterdayBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _ContinueYesterdayBanner({required this.onTap});

  @override
  State<_ContinueYesterdayBanner> createState() =>
      _ContinueYesterdayBannerState();
}

class _ContinueYesterdayBannerState extends State<_ContinueYesterdayBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.accent.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.reply_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Continue from yesterday',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.accent,
                            ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.folder_open_outlined,
                color: AppColors.textSecondary(context), size: 36),
            const SizedBox(height: 12),
            Text(
              'No projects assigned yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
            ),
          ],
        ),
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
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
