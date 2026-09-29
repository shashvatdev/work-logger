import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/regularization_request.dart';
import '../../data/repositories/regularization_repository.dart';
import '../../data/providers/regularization_providers.dart';

class ReviewRequestSheet extends ConsumerStatefulWidget {
  final RegularizationRequest request;
  const ReviewRequestSheet({super.key, required this.request});

  @override
  ConsumerState<ReviewRequestSheet> createState() => _ReviewRequestSheetState();
}

class _ReviewRequestSheetState extends ConsumerState<ReviewRequestSheet> {
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  void _process(bool approve) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(regularizationRepoProvider);
      if (approve) {
        await repo.approveRequest(widget.request.id, _notesCtrl.text.trim());
      } else {
        await repo.rejectRequest(widget.request.id, _notesCtrl.text.trim());
      }
      ref.invalidate(allRequestsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request ${approve ? "Approved" : "Rejected"}'), backgroundColor: approve ? Colors.green : Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.sm),
          Text('Review Request', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          
          Text('Employee: ${req.userName ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Date: ${req.date}'),
          Text('Requested In: ${req.requestedPunchIn != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchIn!).toLocal()) : 'N/A'}'),
          Text('Requested Out: ${req.requestedPunchOut != null ? DateFormat('hh:mm a').format(DateTime.parse(req.requestedPunchOut!).toLocal()) : 'N/A'}'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text('Reason: ${req.reason}'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Admin Notes (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _process(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PremiumButton(
                  label: 'Approve',
                  loading: _loading,
                  onPressed: () => _process(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
