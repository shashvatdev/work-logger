import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      // IndexedStack is managed internally by StatefulShellRoute —
      // each branch keeps its own Navigator alive.
      body: navigationShell,
      bottomNavigationBar: _AdminBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // If user taps the already-selected tab, pop back to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AdminBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _BarItem(icon: Icons.people_outline_rounded, label: 'Team'),
      _BarItem(icon: Icons.folder_open_outlined, label: 'Projects'),
      _BarItem(icon: Icons.search_rounded, label: 'Search'),
    ];

    return SafeArea(
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: AppColors.cardShadowLight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  left: tabWidth * currentIndex + 8,
                  top: 8,
                  bottom: 8,
                  width: tabWidth - 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final selected = currentIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(scale: animation, child: child);
                                },
                                child: Icon(
                                  items[index].icon,
                                  key: ValueKey(selected),
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.textSecondary(context),
                                  size: selected ? 24 : 22,
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: selected
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          items[index].label,
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: AppColors.accent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final String label;
  const _BarItem({required this.icon, required this.label});
}
