import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/providers/regularization_providers.dart';
import '../widgets/review_request_sheet.dart';

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(allRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('All Regularization Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: asyncRequests.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonLoader(height: 140, width: double.infinity, borderRadius: 12),
          ),
        ),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (requests) {
          final pending = requests.where((r) => r.status.toUpperCase() == 'PENDING').toList();
          if (pending.isEmpty) {
            return const Center(child: Text('No pending requests found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final req = pending[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InitialsAvatar(name: req.userName ?? 'U', radius: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(req.userName ?? 'Unknown Employee', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                        Text(req.date, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Requested In: ${req.requestedPunchIn != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchIn!).toLocal()) : 'N/A'} | Out: ${req.requestedPunchOut != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchOut!).toLocal()) : 'N/A'}'),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text('Reason: ${req.reason}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SecondaryButton(
                        label: 'Review',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => ReviewRequestSheet(request: req),
                          );
                        },
                      ),
                    ),
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
