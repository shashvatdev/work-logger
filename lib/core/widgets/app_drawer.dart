import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';
import '../../features/auth/change_password_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin == true;

    return Drawer(
      backgroundColor: AppColors.background(context),
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // ── Premium Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    AppColors.accentDeep.withOpacity(0.04),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.separator(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(
                        name: user?.name ?? 'User',
                        radius: 28,
                        showRing: true,
                      ),
                      const Spacer(),
                      ChipLabel(
                        label: isAdmin ? 'Admin' : 'Employee',
                        color: isAdmin
                            ? AppColors.accent
                            : AppColors.textSecondary(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    user?.name ?? 'Track It User',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Drawer Items ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  _SectionHeader(title: 'PREFERENCES'),

                  // Dark Mode Toggle
                  const _DarkModeTile(),

                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: const AppDivider(),
                  ),

                  _SectionHeader(title: 'ACCOUNT'),

                  // Change Password
                  _DrawerTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your credentials',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),

                  // Logout
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of session',
                    iconColor: AppColors.warning,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),

                  // Delete Account
                  _DrawerTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle: 'Remove account permanently',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: const AppDivider(),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  _SectionHeader(title: 'LEGAL'),

                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we collect & process data',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Privacy Policy',
                      content:
                          'Track It strictly respects your privacy. We collect minimal employee work activity logs solely for project management and internal tracking within your organization.\n\n'
                          '• Personal Information: Name and business email address.\n'
                          '• Logs & Attachments: Work logs and files uploaded by you.\n'
                          '• Data Retention: Stored securely in cloud storage with full SSL encryption.\n'
                          '• Third-Party Sharing: Your data is never sold or shared with external third parties.',
                    ),
                  ),

                  _DrawerTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Rules and terms of usage',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Terms of Service',
                      content:
                          'By accessing or using Track It, you agree to comply with your organization\'s code of conduct and reporting policies.\n\n'
                          '1. Account Security: You are responsible for keeping your login credentials secure.\n'
                          '2. Content Compliance: Log entries and uploaded attachments must conform to workplace standards.\n'
                          '3. Access Termination: Organization admins reserve the right to deactivate employee access at any time.',
                    ),
                  ),

                  _DrawerTile(
                    icon: Icons.shield_outlined,
                    title: 'Data Safety',
                    subtitle: 'App Store & Play Store compliance',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Data Safety & Encryption',
                      content:
                          'In accordance with Google Play Store & Apple App Store Guidelines:\n\n'
                          '• Data Encryption: All data in transit is encrypted using HTTPS/TLS 1.3.\n'
                          '• Secure Token Storage: Access & Refresh JWT tokens are securely saved in device encrypted hardware storage.\n'
                          '• Right to Erasure: Users can request complete account and data removal via the Delete Account option.',
                    ),
                  ),

                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Contact the support team',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Help & Support',
                      content:
                          'Need assistance or found a bug?\n\n'
                          '📧 Email: info@addonshareware.com\n'
                          '📞 Phone: +91 93114 35804\n'
                          '🌐 Website: addonshareware.com\n\n'
                          '🕒 Response Time: Within 24 business hours',
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.separator(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track It',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      Text(
                        'v1.0.0 · © 2026',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 10,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout Action ─────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(ctx);

              await AuthRepository().logout();
              ref.read(currentUserProvider.notifier).state = null;
              ref.invalidate(allProjectsProvider);
              ref.invalidate(myProjectsProvider);
              ref.invalidate(todayLogProvider);
              ref.invalidate(allUsersProvider);

              router.go('/auth');
            },
            child:
                const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete Account Action ─────────────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'This action is PERMANENT. All data associated with this employee will be deleted from the database and cannot be recovered.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              final router = GoRouter.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);

              if (currentUser == null) return;

              final repo = UserRepository();
              final result = await repo.deleteUser(currentUser.id);

              switch (result) {
                case ApiSuccess():
                  await TokenStorage.clearAll();
                  ApiClient.reset();
                  ref.read(currentUserProvider.notifier).state = null;
                  ref.invalidate(allProjectsProvider);
                  ref.invalidate(myProjectsProvider);
                  ref.invalidate(todayLogProvider);
                  ref.invalidate(allUsersProvider);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Account permanently deleted.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  router.go('/auth');
                case ApiError(exception: final ex):
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ex.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
              }
            },
            child: const Text('Yes, Delete Permanently',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Generic Policy Dialog ─────────────────────────────────────────────────
  void _showPolicyDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
          AppSpacing.md, AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
      ),
    );
  }
}

// ─── Drawer Tile ─────────────────────────────────────────────────────────────
class _DrawerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? AppColors.accent;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(widget.icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.textColor,
                                letterSpacing: -0.1,
                              ),
                    ),
                    Text(
                      widget.subtitle,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary(context),
                                fontSize: 11,
                              ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textTertiary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dark Mode Tile ──────────────────────────────────────────────────────────
class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                color: AppColors.accent,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    key: ValueKey(isDark),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isDark ? 'Dark theme enabled' : 'Light theme enabled',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: AppColors.accent,
            onChanged: (bool value) {
              ref.read(themeModeProvider.notifier).toggleDarkMode(value);
            },
          ),
        ],
      ),
    );
  }
}
