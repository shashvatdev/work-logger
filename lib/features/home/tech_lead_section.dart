import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Derives the list of team members the current Tech Lead manages.
///
/// Steps:
///   1. Find all projects where techLeadId == currentUser.id.
///   2. Collect all unique memberIds from those projects.
///   3. Filter allUsers to only those members.
// ─────────────────────────────────────────────────────────────────────────────
final _techLeadTeamProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <UserModel>[];

  final allProjects = await ref.watch(allProjectsProvider.future);
  
  // Projects led by this user
  final ledProjects =
      allProjects.where((p) => p.techLeads.any((tl) => tl.id == user.id) && !p.archived).toList();

  final Map<String, UserModel> uniqueMembers = {};

  // Fetch members for each led project using the project members API
  for (final project in ledProjects) {
    try {
      final members = await ref.watch(projectMembersProvider(project.id).future);
      for (final m in members) {
        if (m.id != user.id) {
          uniqueMembers[m.id] = m;
        }
      }
    } catch (e) {
      // If one project fails to load members, skip it
      continue;
    }
  }

  final teamMembers = uniqueMembers.values.toList();

  // Sort: logged today first, then alphabetically
  teamMembers.sort((a, b) {
    if (a.hasLoggedToday != b.hasLoggedToday) {
      return a.hasLoggedToday ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  });

  return teamMembers;
});

// ─────────────────────────────────────────────────────────────────────────────
/// 'My Team' card shown on the Home Screen for Tech Leads.
// ─────────────────────────────────────────────────────────────────────────────
class TechLeadSection extends ConsumerWidget {
  const TechLeadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(_techLeadTeamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'My Team',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Count badge
                    teamAsync.maybeWhen(
                      data: (members) => members.isEmpty
                          ? const SizedBox.shrink()
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                              ),
                              child: Text(
                                '${members.length}',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/tech-lead/projects'),
                  child: Text(
                    'View Projects',
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

          // ── Card body ────────────────────────────────────────────────────
          teamAsync.when(
            loading: () => SurfaceCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: const SkeletonRow(),
                  ),
                ),
              ),
            ),
            error: (err, _) => SurfaceCard(
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Could not load team members',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            data: (members) => members.isEmpty
                ? SurfaceCard(
                    child: Column(
                      children: [
                        Icon(Icons.group_outlined,
                            color: AppColors.textSecondary(context), size: 32),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No team members yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  )
                : SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < members.length; i++) ...[
                          _TeamMemberRow(member: members[i]),
                          if (i < members.length - 1)
                            const AppDivider(indent: AppSpacing.md + 40 + AppSpacing.sm),
                        ],
                        // ── View All Team Logs CTA ──────────────────────
                        const AppDivider(indent: 0),
                        InkWell(
                          onTap: () => context.push('/tech-lead/projects'),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(AppSpacing.radiusMd)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_outlined,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'View Projects',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Single row for a team member — avatar + name + logged status dot.
// ─────────────────────────────────────────────────────────────────────────────
class _TeamMemberRow extends StatelessWidget {
  final UserModel member;

  const _TeamMemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final logged = member.hasLoggedToday;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          // Avatar
          InitialsAvatar(
            name: member.name,
            radius: AppSpacing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + role chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.isAdmin ? 'Admin' : 'Employee',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),

          // Logged status indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: logged ? AppColors.success : AppColors.dotEmpty,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                logged ? 'Logged Today' : 'Not Logged',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: logged
                          ? AppColors.success
                          : AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
