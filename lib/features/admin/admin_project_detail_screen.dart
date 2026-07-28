import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_extensions.dart';
import '../../data/models/models.dart';
import '../../data/repositories/project_repository.dart';

class AdminProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const AdminProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final timelineAsync = ref.watch(projectTimelineProvider(projectId));

    return projectsAsync.when(
      loading: () => Scaffold(body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: AppSpacing.sm), child: SkeletonRow())))),
      error: (e, st) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (projects) {
        final project = projects.where((p) => p.id == projectId).firstOrNull;
        if (project == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const Center(child: Text('Project not found.')),
          );
        }

        final allUsers = usersAsync.valueOrNull ?? <UserModel>[];
        final members = allUsers.where((u) => project.memberIds.contains(u.id)).toList();

        return Scaffold(
          backgroundColor: AppColors.background(context),
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(project.name, style: Theme.of(context).textTheme.titleLarge),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _ArchiveButton(project: project),
              ),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Members ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                    child: Text(
                      'MEMBERS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < members.length; i++) ...[
                            _MemberRow(member: members[i], project: project),
                            if (i < members.length - 1) const AppDivider(indent: 72),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Add member button ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                    child: _AddMemberButton(project: project, allUsers: allUsers),
                  ),
                ),

                // ── Timeline ───────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                    child: Text(
                      'TIMELINE',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ),
                ),

                timelineAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    )),
                  ),
                  error: (e, st) => SliverToBoxAdapter(
                    child: Center(child: Text('Failed to load timeline')),
                  ),
                  data: (timelineRaw) {
                    final timeline = timelineRaw.map((e) => _TimelineEntry(
                      date: e['date'] ?? '',
                      userName: e['userName'] ?? '',
                      description: e['description'] ?? '',
                      timeSpent: e['timeSpent'] ?? e['hoursSpent'] ?? e['duration'],
                    )).toList();


                    if (timeline.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: EmptyStateWidget(
                            icon: Icons.timeline_outlined,
                            title: 'No activity yet',
                            subtitle: 'Work logged on this project will appear here.',
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = timeline[index];
                            final prevEntry = index > 0 ? timeline[index - 1] : null;
                            final showDateHeader = prevEntry == null || prevEntry.date != entry.date;
                            return StaggeredItem(
                              index: index,
                              child: _TimelineItem(
                                entry: entry,
                                showDateHeader: showDateHeader,
                                isLast: index == timeline.length - 1,
                              ),
                            );
                          },
                          childCount: timeline.length,
                        ),
                      ),
                    );
                  },
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final UserModel member;
  final ProjectModel project;
  const _MemberRow({required this.member, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = member.isAdmin;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      leading: InitialsAvatar(name: member.name, radius: 20, showRing: true),
      title: Row(
        children: [
          Text(member.name, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.accent.withOpacity(0.1) : AppColors.surface(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAdmin ? 'Admin' : 'Employee',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isAdmin ? AppColors.accent : AppColors.textSecondary(context),
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
      trailing: !isAdmin
          ? _RemoveButton(project: project, member: member)
          : null,
    );
  }
}

class _RemoveButton extends ConsumerStatefulWidget {
  final ProjectModel project;
  final UserModel member;
  const _RemoveButton({required this.project, required this.member});
  @override
  ConsumerState<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends ConsumerState<_RemoveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  @override
  void dispose() { _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) async {
        _anim.reverse();
        final repo = ProjectRepository();
        await repo.removeProjectMember(widget.project.id, widget.member.id);
        ref.invalidate(allProjectsProvider);
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(_anim),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.errorSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Remove',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.error,
                  fontSize: 12,
                ),
          ),
        ),
      ),
    );
  }
}

class _AddMemberButton extends ConsumerWidget {
  final ProjectModel project;
  final List<UserModel> allUsers;
  const _AddMemberButton({required this.project, required this.allUsers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = allUsers.where((u) => !u.isAdmin).toList();

    if (employees.isEmpty) return const SizedBox.shrink();

    return SecondaryButton(
      label: 'Assign Employee',
      icon: Icons.person_add_outlined,
      onPressed: () => _showAssignSheet(context, ref, employees),
    );
  }

  void _showAssignSheet(
      BuildContext context, WidgetRef ref, List<UserModel> candidates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(title: 'Assign Employee'),
            const SizedBox(height: 12),
            for (final user in candidates) ...[
              (() {
                final isAlreadyAdded = project.memberIds.contains(user.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  leading: InitialsAvatar(name: user.name, radius: 18),
                  title: Text(user.name,
                      style: Theme.of(context).textTheme.bodyLarge),
                  trailing: isAlreadyAdded
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () async {
                    final repo = ProjectRepository();
                    if (isAlreadyAdded) {
                      await repo.removeProjectMember(project.id, user.id);
                    } else {
                      await repo.addProjectMember(project.id, user.id);
                    }
                    ref.invalidate(allProjectsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }()),
              if (candidates.last.id != user.id)
                const AppDivider(indent: 72),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ArchiveButton extends ConsumerStatefulWidget {
  final ProjectModel project;
  const _ArchiveButton({required this.project});
  @override
  ConsumerState<_ArchiveButton> createState() => _ArchiveButtonState();
}

class _ArchiveButtonState extends ConsumerState<_ArchiveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) async {
        _anim.reverse();
        final repo = ProjectRepository();
        await repo.archiveProject(widget.project.id, !widget.project.archived);
        ref.invalidate(allProjectsProvider);
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(_anim),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: widget.project.archived
                ? AppColors.logDot.withOpacity(0.12)
                : AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.project.archived ? 'Unarchive' : 'Archive',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: widget.project.archived ? AppColors.logDot : AppColors.warning,
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}

class _TimelineEntry {
  final String date;
  final String userName;
  final String description;
  final String? timeSpent;
  const _TimelineEntry({
    required this.date,
    required this.userName,
    required this.description,
    this.timeSpent,
  });
}


class _TimelineItem extends StatelessWidget {
  final _TimelineEntry entry;
  final bool showDateHeader;
  final bool isLast;

  const _TimelineItem({
    required this.entry,
    required this.showDateHeader,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    String dateDisplay = entry.date;
    try {
      dateDisplay = DateFormat('d MMMM').format(DateTime.parse(entry.date));
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeader) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              dateDisplay,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Timeline dot + connector line
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accent.withOpacity(0.3),
                                  AppColors.accent.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 0, bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.userName,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                          ),
                          if (entry.timeSpent != null &&
                              entry.timeSpent!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_filled_rounded,
                                      size: 10, color: AppColors.accent),
                                  const SizedBox(width: 3),
                                  Text(
                                    formatTotalTimeString(entry.timeSpent!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        entry.description.withBulletSpacing,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
