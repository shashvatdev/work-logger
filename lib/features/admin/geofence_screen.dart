import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/admin_providers.dart';
import 'add_edit_office_sheet.dart';

class GeofenceScreen extends ConsumerWidget {
  const GeofenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officesAsync = ref.watch(officesProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Office Locations'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddEditOfficeSheet(),
          );
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(officesProvider);
        },
        child: officesAsync.when(
          data: (offices) {
            if (offices.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  EmptyStateWidget(
                    icon: Icons.location_off,
                    title: 'No Offices Found',
                    subtitle: 'Add an office location to set up geofencing.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: offices.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final office = offices[index];
                return Dismissible(
                  key: ValueKey(office.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Office?'),
                        content: Text('Are you sure you want to delete ${office.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    final repo = ref.read(geofenceRepositoryProvider);
                    await repo.deleteOffice(office.id);
                    ref.invalidate(officesProvider);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: SurfaceCard(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddEditOfficeSheet(office: office),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    office.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: office.isActive ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              if (office.address != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  office.address!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary(context),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ChipLabel(
                          label: '${office.radiusInMeters.toInt()}m',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, __) => const SkeletonLoader(width: double.infinity, height: 80),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
