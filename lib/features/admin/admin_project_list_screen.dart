import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/project_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';

class AdminProjectListScreen extends ConsumerWidget {
  const AdminProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);

    return projectsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const SkeletonRow(),
      ),
      error: (e, st) => Center(child: Text(e.toString())),
      data: (allProjects) {
        final active = allProjects.where((p) => !p.archived).toList();
        final archived = allProjects.where((p) => p.archived).toList();

        final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sm;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, topPadding, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projects',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.0,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${active.length} active',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                        ),
                      ],
                    ),
                    _CreateProjectButton(),
                  ],
                ),
              ),
            ),

            // ── Active projects ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.textSecondary(context)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'ACTIVE',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: active.isEmpty
                    ? SurfaceCard(
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: EmptyStateWidget(
                              icon: Icons.folder_open_rounded,
                              title: 'No active projects',
                              subtitle: 'Create one to get started.',
                            ),
                          ),
                        ),
                      )
                    : SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < active.length; i++) ...[
                              StaggeredItem(
                                index: i,
                                child: _ProjectRow(project: active[i]),
                              ),
                              if (i < active.length - 1)
                                const AppDivider(indent: 68),
                            ],
                          ],
                        ),
                      ),
              ),
            ),

            // ── Archived projects ─────────────────────────────────────────────────
            if (archived.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 16, color: AppColors.textSecondary(context)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'ARCHIVED',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondary(context),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (int i = 0; i < archived.length; i++) ...[
                          StaggeredItem(
                            index: i,
                            child: _ProjectRow(project: archived[i], archived: true),
                          ),
                          if (i < archived.length - 1)
                            const AppDivider(indent: 68),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final ProjectModel project;
  final bool archived;
  const _ProjectRow({required this.project, this.archived = false});

  @override
  Widget build(BuildContext context) {
    final projectColor = AppColors.projectColor(project.id);
    return Opacity(
      opacity: archived ? 0.5 : 1.0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: projectColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder_rounded, color: projectColor, size: 22),
        ),
        title: Text(
          project.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: archived ? AppColors.textSecondary(context) : null,
              ),
        ),
        subtitle: Text(
          '${project.memberCount} members',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (archived)
              ChipLabel(
                  label: 'Archived',
                  color: AppColors.textSecondary(context)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary(context), size: 20),
          ],
        ),
        onTap: () => context.push('/admin/projects/${project.id}'),
      ),
    );
  }
}

class _CreateProjectButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateProjectButton> createState() => _CreateProjectButtonState();
}

class _CreateProjectButtonState extends ConsumerState<_CreateProjectButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  
  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        _showCreateDialog(context, ref);
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.accentShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Text(
                'New',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(title: 'New Project', subtitle: 'Create a workspace for your team'),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Project name',
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumButton(
                  label: 'Create Project',
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    
                    final repo = ProjectRepository();
                    await repo.createProject(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    
                    ref.invalidate(allProjectsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
