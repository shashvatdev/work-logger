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
      loading: () => const Center(child: CircularProgressIndicator()),
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
                          style: Theme.of(context).textTheme.displayLarge,
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
                child: Text(
                  'ACTIVE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary(context),
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: active.isEmpty
                    ? SurfaceCard(
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: Text(
                              'No active projects.\nCreate one to get started.',
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary(context),
                                      ),
                            ),
                          ),
                        ),
                      )
                    : SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < active.length; i++) ...[
                              _ProjectRow(project: active[i]),
                              if (i < active.length - 1)
                                const AppDivider(indent: AppSpacing.md),
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
                  child: Text(
                    'ARCHIVED',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary(context),
                        ),
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
                          _ProjectRow(project: archived[i], archived: true),
                          if (i < archived.length - 1)
                            const AppDivider(indent: AppSpacing.md),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 8),
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
    );
  }
}

class _CreateProjectButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showCreateDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.separator(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('New Project',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration:
                      const InputDecoration(hintText: 'Project name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                      hintText: 'Description (optional)'),
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
