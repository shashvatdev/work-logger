import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/admin_providers.dart';
import '../../data/models/office_model.dart';

class AddEditOfficeSheet extends ConsumerStatefulWidget {
  final OfficeModel? office;
  const AddEditOfficeSheet({super.key, this.office});

  @override
  ConsumerState<AddEditOfficeSheet> createState() => _AddEditOfficeSheetState();
}

class _AddEditOfficeSheetState extends ConsumerState<AddEditOfficeSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  double _radius = 100;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.office?.name);
    _addressCtrl = TextEditingController(text: widget.office?.address);
    _latCtrl = TextEditingController(text: widget.office?.latitude.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.office?.longitude.toString() ?? '');
    if (widget.office != null) {
      _radius = widget.office!.radiusInMeters;
    } else {
      _fetchCurrentLocation();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      if (mounted) {
        setState(() {
          _latCtrl.text = position.latitude.toString();
          _lngCtrl.text = position.longitude.toString();
        });
      }
    } catch (_) {
      // Silently ignore if location fails, user can type it manually
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    final repo = ref.read(geofenceRepositoryProvider);
    
    final lat = double.tryParse(_latCtrl.text) ?? 0.0;
    final lng = double.tryParse(_lngCtrl.text) ?? 0.0;
    
    if (widget.office == null) {
      await repo.createOffice(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusInMeters: _radius,
      );
    } else {
      await repo.updateOffice(
        widget.office!.id,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusInMeters: _radius,
      );
    }
    
    ref.invalidate(officesProvider);
    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Text(
              widget.office == null ? 'Add Office' : 'Edit Office',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Office Name *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
                if (_isFetchingLocation)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm, bottom: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (widget.office == null)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 4),
                    child: IconButton(
                      onPressed: _fetchCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 22),
                      tooltip: 'Get current location',
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, size: 20, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Radius: ${_radius.toInt()} meters',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(40, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _radius > 10
                          ? () => setState(() => _radius = (_radius - 10).clamp(10.0, 1000.0))
                          : null,
                      child: const Text('-10m', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(40, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _radius < 1000
                          ? () => setState(() => _radius = (_radius + 10).clamp(10.0, 1000.0))
                          : null,
                      child: const Text('+10m', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            Slider(
              value: _radius.clamp(10.0, 500.0),
              min: 10,
              max: 500,
              divisions: 49,
              label: '${_radius.toInt()}m',
              onChanged: (val) => setState(() => _radius = (val / 10).round() * 10.0),
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Save',
              onPressed: _save,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
