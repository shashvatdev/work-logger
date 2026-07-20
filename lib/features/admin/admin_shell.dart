import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: child,
      bottomNavigationBar: _AdminBottomBar(currentLocation: location),
    );
  }
}

class _AdminBottomBar extends ConsumerWidget {
  final String currentLocation;
  const _AdminBottomBar({required this.currentLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _BarItem(
          icon: Icons.people_outline_rounded,
          label: 'Team',
          route: '/admin/employees'),
      _BarItem(
          icon: Icons.folder_open_outlined,
          label: 'Projects',
          route: '/admin/projects'),
      _BarItem(
          icon: Icons.search_rounded,
          label: 'Search',
          route: '/search'),
    ];

    return SafeArea(
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.elevated(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: items.map((item) {
            final selected = currentLocation.startsWith(item.route);
            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary(context),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textSecondary(context),
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final String label;
  final String route;
  const _BarItem(
      {required this.icon, required this.label, required this.route});
}
