import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:track_it/core/theme/app_colors.dart';
import 'package:track_it/core/theme/app_spacing.dart';
import 'package:track_it/core/widgets/widgets.dart';
import 'package:track_it/features/attendance/data/models/assigned_office.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/assigned_office.dart';

class AttendancePunchMapScreen extends StatefulWidget {
  final bool isPunchIn;
  final AssignedOffice office;
  final DateTime? punchInTime;

  const AttendancePunchMapScreen({
    super.key,
    required this.isPunchIn,
    required this.office,
    this.punchInTime,
  });

  @override
  State<AttendancePunchMapScreen> createState() => _AttendancePunchMapScreenState();
}

class _AttendancePunchMapScreenState extends State<AttendancePunchMapScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  double? _distance;
  bool _isMocked = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _error = 'Please turn on GPS and try again.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.office.latitude,
        widget.office.longitude,
      );

      setState(() {
        _currentPosition = position;
        _distance = distance;
        _isMocked = position.isMocked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWithinRange = _distance != null && _distance! <= widget.office.radiusInMeters;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackChevron(),
        ),
        title: Text(
          'Verify Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SurfaceCard(
                child: Column(
                  children: [
                    // Location info card
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.business, color: AppColors.accent),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.office.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Radius: ${widget.office.radiusInMeters.toStringAsFixed(0)}m',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Visual representation
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Geofence circle
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isWithinRange ? AppColors.success : AppColors.error).withOpacity(0.1),
                                border: Border.all(
                                  color: isWithinRange ? AppColors.success : AppColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            // Office icon
                            const Icon(Icons.business, size: 40, color: AppColors.accent),
                            
                            // User dot (simplified logic for visual representation)
                            if (_distance != null)
                              Positioned(
                                top: isWithinRange ? 120 : 10,
                                left: isWithinRange ? 120 : 10,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: AppColors.floatShadow,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_error != null)
                      Text(_error!, style: TextStyle(color: AppColors.error))
                    else ...[
                      Text(
                        'You are ${_distance?.toStringAsFixed(0)}m from ${widget.office.name}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: (isWithinRange ? AppColors.success : AppColors.error).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWithinRange ? Icons.check_circle : Icons.cancel,
                              color: isWithinRange ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              isWithinRange ? 'Within Range' : 'Outside Geofence',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: isWithinRange ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_isMocked) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Mocked GPS detected',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.error),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Area
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.elevated(context),
              border: Border(top: BorderSide(color: AppColors.separator(context), width: 0.5)),
            ),
            child: SafeArea(
              child: _isLoading
                  ? Center(child: Text('Verifying your location...', style: TextStyle(color: AppColors.textSecondary(context))))
                  : PremiumButton(
                      label: widget.isPunchIn ? 'Punch In' : 'Punch Out',
                      icon: widget.isPunchIn ? Icons.login : Icons.logout,
                      backgroundColor: (isWithinRange && !_isMocked) ? AppColors.success : AppColors.separator(context),
                      useGradient: false,
                      onPressed: (isWithinRange && !_isMocked)
                          ? () => context.pop(true)
                          : () {
                              if (_isMocked) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Invalid Location'),
                                    content: const Text('Mocked GPS detected. Please use real location to punch in.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You are outside the geofence range.'), backgroundColor: AppColors.error),
                                );
                              }
                            },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
