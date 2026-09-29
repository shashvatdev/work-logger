import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withBackground;

  const AppLogo({
    super.key,
    this.size = 100,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.55;
    final strokeWidth = size * 0.12;

    Widget logoContent = SizedBox(
      width: innerSize,
      height: innerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Horizontal bar of 'T'
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: strokeWidth,
              decoration: BoxDecoration(
                color: withBackground ? Colors.white : AppColors.accent,
                borderRadius: BorderRadius.circular(strokeWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Vertical bar of 'T'
          Positioned(
            top: strokeWidth + (size * 0.04), // slight gap
            bottom: strokeWidth * 1.5,
            child: Container(
              width: strokeWidth,
              decoration: BoxDecoration(
                color: withBackground ? Colors.white : AppColors.accent,
                borderRadius: BorderRadius.circular(strokeWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Tracking/Location Dot (Green)
          Positioned(
            bottom: 0,
            child: Container(
              width: strokeWidth * 1.2,
              height: strokeWidth * 1.2,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: withBackground ? AppColors.accent : Colors.white,
                  width: size * 0.02,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!withBackground) {
      return SizedBox(width: size, height: size, child: Center(child: logoContent));
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(size * 0.22), // iOS style squircle
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(child: logoContent),
    );
  }
}
