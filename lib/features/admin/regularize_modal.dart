import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/api/api_exception.dart';

class RegularizeModal extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String dateStr;

  const RegularizeModal({
    super.key,
    required this.userId,
    required this.userName,
    required this.dateStr,
  });

  @override
  ConsumerState<RegularizeModal> createState() => _RegularizeModalState();
}

class _RegularizeModalState extends ConsumerState<RegularizeModal> {
  TimeOfDay? _punchInTime;
  TimeOfDay? _punchOutTime;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isPunchIn) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isPunchIn ? (_punchInTime ?? TimeOfDay.now()) : (_punchOutTime ?? _punchInTime ?? TimeOfDay.now()),
    );
    if (time != null && mounted) {
      if (isPunchIn && _punchOutTime != null) {
        final inMinutes = time.hour * 60 + time.minute;
        final outMinutes = _punchOutTime!.hour * 60 + _punchOutTime!.minute;
        if (inMinutes >= outMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Punch In time must be before Punch Out time'), backgroundColor: Colors.red),
          );
          return;
        }
      } else if (!isPunchIn && _punchInTime != null) {
        final inMinutes = _punchInTime!.hour * 60 + _punchInTime!.minute;
        final outMinutes = time.hour * 60 + time.minute;
        if (outMinutes <= inMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Punch Out time must be after Punch In time'), backgroundColor: Colors.red),
          );
          return;
        }
      }

      setState(() {
        if (isPunchIn) {
          _punchInTime = time;
        } else {
          _punchOutTime = time;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    if (_punchInTime == null || _punchOutTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Punch In and Punch Out times')),
      );
      return;
    }

    final inMinutes = _punchInTime!.hour * 60 + _punchInTime!.minute;
    final outMinutes = _punchOutTime!.hour * 60 + _punchOutTime!.minute;
    if (outMinutes <= inMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punch Out time must be after Punch In time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final repo = ref.read(adminRepositoryProvider);
    final inTimeStr = '${widget.dateStr}T${_formatTime(_punchInTime)}:00Z'; // Format assumption, might need tweaking depending on backend
    final outTimeStr = '${widget.dateStr}T${_formatTime(_punchOutTime)}:00Z';

    final res = await repo.regularizeAttendance(
      widget.userId,
      punchInTime: inTimeStr,
      punchOutTime: outTimeStr,
      adminNotes: _notesCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (res.isSuccess) {
        ref.invalidate(allAttendanceDateProvider(widget.dateStr));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance regularized successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.error.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      backgroundColor: AppColors.elevated(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Regularize Attendance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Employee: ${widget.userName}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: _punchInTime == null ? 'Set Punch In' : 'In: ${_formatTime(_punchInTime)}',
                    onPressed: () => _pickTime(true),
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SecondaryButton(
                    label: _punchOutTime == null ? 'Set Punch Out' : 'Out: ${_formatTime(_punchOutTime)}',
                    onPressed: () => _pickTime(false),
                    icon: Icons.access_time_filled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Admin Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Submit',
              onPressed: _submit,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
