import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
export 'app_drawer.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Premium surface card with press-lift animation and layered shadows.
// ─────────────────────────────────────────────────────────────────────────────
class SurfaceCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasShadow;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSpacing.radiusMd,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.984).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
    _elevation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (context, child) => Transform.scale(
        scale: widget.onTap != null ? _scale.value : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: isDark
                ? Border.all(
                    color: AppColors.separatorDark.withOpacity(0.6),
                    width: 0.5,
                  )
                : null,
            boxShadow: widget.hasShadow && !isDark
                ? AppColors.cardShadowLight
                    .map((s) => BoxShadow(
                          color: s.color.withOpacity(
                              s.color.opacity * _elevation.value),
                          blurRadius: s.blurRadius,
                          spreadRadius: s.spreadRadius,
                          offset: s.offset,
                        ))
                    .toList()
                : null,
          ),
          child: widget.onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTapDown: (_) => _pressCtrl.forward(),
                    onTapUp: (_) {
                      _pressCtrl.reverse();
                      widget.onTap?.call();
                    },
                    onTapCancel: () => _pressCtrl.reverse(),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    overlayColor:
                        WidgetStateProperty.all(AppColors.accent.withOpacity(0.04)),
                    child: Padding(
                      padding: widget.padding ??
                          const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                      child: child,
                    ),
                  ),
                )
              : Padding(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                  child: child,
                ),
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Large primary CTA button — gradient fill, spring press, success state.
// ─────────────────────────────────────────────────────────────────────────────
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final bool useGradient;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height = AppSpacing.buttonHeightLg,
    this.useGradient = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.loading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.accent;
    final fg = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: (widget.useGradient && widget.backgroundColor == null)
                ? AppColors.accentGradient
                : null,
            color: (widget.useGradient && widget.backgroundColor == null)
                ? null
                : bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: widget.onPressed != null && !widget.loading
                ? AppColors.accentShadow
                : null,
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: fg,
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
/// Subtle secondary button with spring press.
// ─────────────────────────────────────────────────────────────────────────────
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: AppSpacing.buttonHeightSm,
          decoration: BoxDecoration(
            color: AppColors.accentMid,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
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
/// Separator divider
// ─────────────────────────────────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  final double indent;
  const AppDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: AppColors.separator(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Animated status dot — pulses when active
// ─────────────────────────────────────────────────────────────────────────────
class StatusDot extends StatefulWidget {
  final bool active;
  final double size;
  const StatusDot({super.key, required this.active, this.size = 8});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: widget.active ? _pulse.value : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.active ? AppColors.logDot : AppColors.dotEmpty,
            shape: BoxShape.circle,
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.logDot.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 0,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Chip-style label with animated appearance
// ─────────────────────────────────────────────────────────────────────────────
class ChipLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const ChipLabel({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: c.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Apple-style back chevron
// ─────────────────────────────────────────────────────────────────────────────
class BackChevron extends StatelessWidget {
  final String? label;
  const BackChevron({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left_rounded, color: AppColors.accent, size: 30),
          if (label != null)
            Text(
              label!,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Premium avatar with gradient ring
// ─────────────────────────────────────────────────────────────────────────────
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool showRing;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.showRing = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(isDark ? 0.25 : 0.15),
            AppColors.accentDeep.withOpacity(isDark ? 0.18 : 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.65,
            letterSpacing: 0,
          ),
        ),
      ),
    );

    if (!showRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background(context),
        ),
        child: avatar,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Skeleton shimmer loading widget
// ─────────────────────────────────────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8EC);
    final shimmerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [baseColor, shimmerColor, baseColor],
              transform: _SlidingGradientTransform(_shimmer.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Skeleton card row (employee/project row placeholder)
// ─────────────────────────────────────────────────────────────────────────────
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          SkeletonLoader(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: double.infinity, height: 14, borderRadius: 7),
                const SizedBox(height: AppSpacing.xs),
                SkeletonLoader(width: 120, height: 11, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SkeletonLoader(width: 20, height: 20, borderRadius: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Reusable animated empty state
// ─────────────────────────────────────────────────────────────────────────────
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _float;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? AppColors.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _float.value),
                child: child,
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                ),
                child: Icon(widget.icon, color: iconColor, size: 34),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary(context),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Staggered list item fade+slide entrance
// ─────────────────────────────────────────────────────────────────────────────
class StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Animated counter — number rolls to target
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, this.style});

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previousValue = old.value;
      _anim = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
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
      builder: (context, child) => Text(
        _anim.value.round().toString(),
        style: widget.style,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Bottom sheet drag handle + header pattern
// ─────────────────────────────────────────────────────────────────────────────
class SheetHandle extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const SheetHandle({super.key, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.separator(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title!,
                    style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
