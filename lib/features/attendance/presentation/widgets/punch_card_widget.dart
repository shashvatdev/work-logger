import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/attendance_provider.dart';
import '../../data/models/attendance_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Home-screen Punch Card — matches the app's premium design language.
/// Handles 3 states: Not Punched In / Punched In (live timer) / Completed.
// ─────────────────────────────────────────────────────────────────────────────
class PunchCardWidget extends ConsumerStatefulWidget {
  const PunchCardWidget({super.key});

  @override
  ConsumerState<PunchCardWidget> createState() => _PunchCardWidgetState();
}

class _PunchCardWidgetState extends ConsumerState<PunchCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer(DateTime punchInTime) {
    _timer?.cancel();
    _elapsed = DateTime.now().difference(punchInTime);
    _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(punchInTime));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _pulseCtrl.stop();
    _pulseCtrl.reset();
  }

  String _formatDuration(Duration d) {
    String twoD(int n) => n.toString().padLeft(2, '0');
    return '${twoD(d.inHours)}:${twoD(d.inMinutes.remainder(60))}:${twoD(d.inSeconds.remainder(60))}';
  }

  Future<void> _handlePunch({required bool isPunchIn}) async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Please turn on GPS / Location Services and try again.');
      }

      // 2. Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied. Please enable it from Settings.');
      }

      // 3. Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      // 4. Anti-cheat: mock/fake GPS check
      if (position.isMocked) {
        if (mounted) _showMockGpsDialog();
        return;
      }

      // 5. API call
      final apiService = ref.read(attendanceApiServiceProvider);
      if (isPunchIn) {
        await apiService.punchIn(position.latitude, position.longitude);
      } else {
        await apiService.punchOut(position.latitude, position.longitude);
      }

      ref.invalidate(attendanceStatusProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMockGpsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.gps_off_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            const Text('Fake GPS Detected'),
          ],
        ),
        content: const Text(
          'Mock / Fake GPS location has been detected on your device.\n\nPlease disable any mock location apps and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.isSuperAdmin == true) {
      return const SizedBox.shrink();
    }

    final statusAsync = ref.watch(attendanceStatusProvider);

    return statusAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => _buildError(context, e),
      data: (status) {
        // Manage timer lifecycle based on status
        if (status.isPunchedIn &&
            !status.isCompletedForToday &&
            status.todayRecord?.punchInTime != null) {
          if (_timer == null || !_timer!.isActive) {
            _startTimer(status.todayRecord!.punchInTime!);
          }
        } else {
          if (_timer != null && _timer!.isActive) _stopTimer();
        }

        return _buildCard(context, status);
      },
    );
  }

  // ── Main Card ──────────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, AttendanceStatus status) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: isDark
              ? Border.all(
                  color: AppColors.separatorDark.withOpacity(0.5), width: 0.5)
              : null,
          boxShadow: isDark ? null : AppColors.cardShadowLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, status),
            const SizedBox(height: AppSpacing.sm),
            _buildBody(context, status),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ── Header: Office info + status pill ─────────────────────────────────────
  Widget _buildHeader(BuildContext context, AttendanceStatus status) {
    final office = status.assignedOffice;
    final color = status.isCompletedForToday
        ? AppColors.success
        : status.isPunchedIn
            ? AppColors.warning
            : AppColors.accent;

    final statusLabel = status.isCompletedForToday
        ? 'Completed'
        : status.isPunchedIn
            ? 'On Duty'
            : 'Not Clocked In';

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.location_on_rounded, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  office?.name ?? 'No Office Assigned',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (office != null)
                  Text(
                    '${office.radiusInMeters.toInt()}m allowed radius',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Status Pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: color.withOpacity(0.25), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status.isPunchedIn && !status.isCompletedForToday)
                  _PulsingDot(color: color),
                if (status.isPunchedIn && !status.isCompletedForToday)
                  const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: Timer / Button ───────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, AttendanceStatus status) {
    if (_isLoading) return _buildLoadingState(context);
    if (status.isCompletedForToday) return _buildCompletedState(context, status);
    if (status.isPunchedIn) return _buildPunchedInState(context, status);
    return _buildPunchInState(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Verifying GPS…',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchInState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Column(
        children: [
          // Time display
          Text(
            _formatDuration(Duration.zero),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context).withOpacity(0.2),
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You haven't clocked in yet",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PunchButton(
            label: 'Punch In',
            icon: Icons.login_rounded,
            color: AppColors.success,
            onTap: () => _handlePunch(isPunchIn: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchedInState(BuildContext context, AttendanceStatus status) {
    final punchIn = status.todayRecord?.punchInTime;
    final timeStr = punchIn != null
        ? '${punchIn.hour.toString().padLeft(2, '0')}:${punchIn.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Column(
        children: [
          // Live stopwatch
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) =>
                Transform.scale(scale: _pulse.value, child: child),
            child: Text(
              _formatDuration(_elapsed),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded,
                  size: 13, color: AppColors.textSecondary(context)),
              const SizedBox(width: 4),
              Text(
                'Clocked in at $timeStr',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PunchButton(
            label: 'Punch Out',
            icon: Icons.logout_rounded,
            color: AppColors.error,
            onTap: () => _handlePunch(isPunchIn: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, AttendanceStatus status) {
    final record = status.todayRecord;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.1),
            ),
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Completed for Today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: 4),
          if (record?.workingTimeFormatted != null)
            Text(
              'Total: ${record!.workingTimeFormatted}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
            ),
          // In/Out times row
          if (record?.punchInTime != null && record?.punchOutTime != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeChip(
                    icon: Icons.login_rounded,
                    label: 'In',
                    time: _hhmm(record!.punchInTime!),
                    color: AppColors.success,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textTertiary(context)),
                  ),
                  _TimeChip(
                    icon: Icons.logout_rounded,
                    label: 'Out',
                    time: _hhmm(record.punchOutTime!),
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: AppColors.isDark(context) ? null : AppColors.cardShadowLight,
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Could not load attendance status',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(attendanceStatusProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
/// Punch Action Button — spring-press, gradient fill, icon + label.
// ─────────────────────────────────────────────────────────────────────────────
class _PunchButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PunchButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PunchButton> createState() => _PunchButtonState();
}

class _PunchButtonState extends State<_PunchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: AppSpacing.buttonHeightLg,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Animated pulsing live indicator dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Small time chip for completed state
// ─────────────────────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
