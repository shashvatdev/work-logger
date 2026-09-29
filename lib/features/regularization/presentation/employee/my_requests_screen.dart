import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/providers/regularization_providers.dart';
import '../widgets/new_request_sheet.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('My Regularizations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const NewRequestSheet(),
          );
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: asyncRequests.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonLoader(height: 120, width: double.infinity, borderRadius: 12),
          ),
        ),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No requests found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              Color statusColor = AppColors.warning;
              if (req.status.toUpperCase() == 'APPROVED') statusColor = AppColors.success;
              if (req.status.toUpperCase() == 'REJECTED') statusColor = AppColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.date, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ChipLabel(label: req.status, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Requested In: ${req.requestedPunchIn != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchIn!).toLocal()) : 'N/A'} | Out: ${req.requestedPunchOut != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchOut!).toLocal()) : 'N/A'}'),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Reason: ${req.reason}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary(context))),
                      if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text('Admin Notes: ${req.adminNotes}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
