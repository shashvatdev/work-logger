import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';

class TechLeadProjectsScreen extends ConsumerWidget {
  const TechLeadProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: projectsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => const SkeletonRow(),
        ),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (allProjects) {
          final ledProjects = allProjects
              .where((p) => p.techLeads.any((tl) => tl.id == user?.id) && !p.archived)
              .toList();

          if (ledProjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyStateWidget(
                  icon: Icons.folder_open_rounded,
                  title: 'No led projects',
                  subtitle: 'You are not leading any projects currently.',
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: ledProjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final project = ledProjects[index];
              final projectColor = AppColors.projectColor(project.id);

              return SurfaceCard(
                padding: EdgeInsets.zero,
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
                    child: Icon(Icons.folder_rounded,
                        color: projectColor, size: 22),
                  ),
                  title: Text(
                    project.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '${project.memberCount} members',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary(context), size: 20),
                  onTap: () => context.push('/projects/${project.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
