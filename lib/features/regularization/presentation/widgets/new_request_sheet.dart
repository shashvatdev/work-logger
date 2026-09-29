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

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid Selection'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_punchIn == null) {
      _showError('Please select Punch In time');
      return;
    }
    if (_punchOut == null) {
      _showError('Please select Punch Out time');
      return;
    }

    final inMinutes = _punchIn!.hour * 60 + _punchIn!.minute;
    final outMinutes = _punchOut!.hour * 60 + _punchOut!.minute;
    if (outMinutes <= inMinutes) {
      _showError('Punch Out time must be after Punch In time');
      return;
    }

    if (_reasonCtrl.text.trim().isEmpty) {
      _showError('Please provide a reason');
      return;
    }

    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final inStr = '${dateStr}T${_punchIn!.hour.toString().padLeft(2, '0')}:${_punchIn!.minute.toString().padLeft(2, '0')}:00';
      final outStr = '${dateStr}T${_punchOut!.hour.toString().padLeft(2, '0')}:${_punchOut!.minute.toString().padLeft(2, '0')}:00';
      
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
        _showError('Error: ${e.toString()}');
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
                    final t = await showTimePicker(
                        context: context, 
                        initialTime: _punchIn ?? TimeOfDay.now()
                    );
                    if (t != null) {
                      if (_punchOut != null) {
                        final inMinutes = t.hour * 60 + t.minute;
                        final outMinutes = _punchOut!.hour * 60 + _punchOut!.minute;
                        if (inMinutes >= outMinutes) {
                          _showError('Punch In time (${t.format(context)}) must be before Punch Out time (${_punchOut!.format(context)}).');
                          return;
                        }
                      }
                      setState(() => _punchIn = t);
                    }
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
                    final initialTime = _punchOut ??
                        (_punchIn != null
                            ? TimeOfDay(hour: (_punchIn!.hour + 1) % 24, minute: _punchIn!.minute)
                            : TimeOfDay.now());
                    final t = await showTimePicker(
                        context: context, 
                        initialTime: initialTime
                    );
                    if (t != null) {
                      if (_punchIn != null) {
                        final inMinutes = _punchIn!.hour * 60 + _punchIn!.minute;
                        final outMinutes = t.hour * 60 + t.minute;
                        if (outMinutes <= inMinutes) {
                          _showError('Punch Out time (${t.format(context)}) must be after Punch In time (${_punchIn!.format(context)}).');
                          return;
                        }
                      }
                      setState(() => _punchOut = t);
                    }
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
