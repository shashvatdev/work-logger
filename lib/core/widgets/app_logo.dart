import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;

  const AppLogo({
    super.key,
    this.size = 100,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? (size * 0.22)),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
