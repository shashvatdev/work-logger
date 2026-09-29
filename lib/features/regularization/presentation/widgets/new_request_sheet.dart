import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/repositories/regularization_repository.dart';
import '../../data/providers/regularization_providers.dart';

class NewRequestSheet extends ConsumerStatefulWidget {
  const NewRequestSheet({super.key});

  @override
  ConsumerState<NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<NewRequestSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _punchIn;
  TimeOfDay? _punchOut;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  void _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date'), backgroundColor: Colors.red));
      return;
    }
    if (_punchIn == null && _punchOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide at least one punch time'), backgroundColor: Colors.red));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a reason'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final inStr = _punchIn != null ? '${dateStr}T${_punchIn!.hour.toString().padLeft(2, '0')}:${_punchIn!.minute.toString().padLeft(2, '0')}:00' : null;
      final outStr = _punchOut != null ? '${dateStr}T${_punchOut!.hour.toString().padLeft(2, '0')}:${_punchOut!.minute.toString().padLeft(2, '0')}:00' : null;
      
      await ref.read(regularizationRepoProvider).submitRequest(
        date: dateStr,
        punchIn: inStr,
        punchOut: outStr,
        reason: _reasonCtrl.text.trim(),
      );
      
      ref.invalidate(myRequestsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully'), backgroundColor: Colors.green));
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
          Text('New Regularization Request', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          
          ListTile(
            title: Text(_selectedDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_selectedDate!)),
            trailing: const Icon(Icons.calendar_month, color: AppColors.accent),
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) setState(() => _selectedDate = d);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(_punchIn == null ? 'Punch In' : _punchIn!.format(context)),
                  trailing: const Icon(Icons.access_time, color: AppColors.accent),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setState(() => _punchIn = t);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ListTile(
                  title: Text(_punchOut == null ? 'Punch Out' : _punchOut!.format(context)),
                  trailing: const Icon(Icons.access_time, color: AppColors.accent),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setState(() => _punchOut = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            label: 'Submit Request',
            loading: _loading,
            loadingLabel: 'Submitting...',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
