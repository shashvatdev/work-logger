import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/change_password_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.background(context),
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.elevated(context),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.separator(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  InitialsAvatar(
                    name: user?.name ?? 'User',
                    radius: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'WorkNote User',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ChipLabel(
                          label: user?.isAdmin == true ? 'Admin' : 'Employee',
                          color: user?.isAdmin == true
                              ? AppColors.accent
                              : AppColors.textSecondary(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Drawer Items ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  _SectionHeader(title: 'PREFERENCES'),

                  // Dark Mode Toggle
                  const _DarkModeTile(),

                  const SizedBox(height: AppSpacing.xs),
                  const AppDivider(),

                  _SectionHeader(title: 'ACCOUNT'),
                  
                  // Change Password (Functional)
                  _DrawerTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),

                  // Logout (Functional)
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of current session',
                    iconColor: Colors.orangeAccent,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),

                  // Delete Account (Store policy requirement)
                  _DrawerTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove account & data',
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  const AppDivider(),
                  const SizedBox(height: AppSpacing.sm),

                  _SectionHeader(title: 'STORE POLICIES & LEGAL'),

                  // Privacy Policy
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we collect & process data',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Privacy Policy',
                      content:
                          'WorkNote strictly respects your privacy. We collect minimal employee work activity logs solely for project management and internal tracking within your organization.\n\n'
                          '• Personal Information: Name and business email address.\n'
                          '• Logs & Attachments: Work logs and files uploaded by you.\n'
                          '• Data Retention: Stored securely in cloud storage with full SSL encryption.\n'
                          '• Third-Party Sharing: Your data is never sold or shared with external third parties.',
                    ),
                  ),

                  // Terms of Service
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Rules and terms of usage',
                    onTap: () => _showPolicyDialog(
                      context,
                      title: 'Terms of Service',
                      content:
                          'By accessing or using WorkNote, you agree to comply with your organization\'s code of conduct and reporting policies.\n\n'
                          '1. Account Security: You are responsible for keeping your login credentials secure.\n'
                          '2. Content Compliance: Log entries and uploaded attachments must conform to workplace standards.\n'
                          '3. Access Termination: Organization admins reserve the right to deactivate employee access at any time.',
                    ),
                  ),

                  // Data Safety & Protection
                  _DrawerTile(
                    icon: Icons.shield_outlined,
                    title: 'Data Safety & Encryption',
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

                  // Help & Support
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Contact support team',
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

            // ── Drawer Footer ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.separator(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'WorkNote v1.0.0 (1)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2026 WorkNote Inc. All rights reserved.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary(context).withOpacity(0.7),
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout Action ────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated(ctx),
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
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer

              await AuthRepository().logout();
              ref.read(currentUserProvider.notifier).state = null;
              ref.invalidate(allProjectsProvider);
              ref.invalidate(myProjectsProvider);
              ref.invalidate(todayLogProvider);
              ref.invalidate(allUsersProvider);

              if (context.mounted) {
                context.go('/auth');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete Account Action (Play Store & App Store Requirement) ───────────
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated(ctx),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'As per App Store & Google Play Store guidelines, you can request account and data deletion.\n\n'
          'Are you sure you want to request permanent deletion of your account and all associated work logs? This action cannot be undone.',
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
              Navigator.pop(ctx);
              Navigator.pop(context);

              // Perform logout and notify user about deletion request
              await AuthRepository().logout();
              ref.read(currentUserProvider.notifier).state = null;
              ref.invalidate(allProjectsProvider);
              ref.invalidate(myProjectsProvider);
              ref.invalidate(todayLogProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Account deletion request submitted. Session ended.'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.go('/auth');
              }
            },
            child: const Text('Delete Account',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Generic Policy Dialog ────────────────────────────────────────────────
  void _showPolicyDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated(ctx),
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(ctx).textTheme.bodyMedium,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.accent,
        size: 22,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary(context),
            ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondary(context),
      ),
      onTap: onTap,
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: AppColors.accent,
        size: 22,
      ),
      title: Text(
        'Dark Mode',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        isDark ? 'Dark theme enabled' : 'Light theme enabled',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary(context),
            ),
      ),
      activeThumbColor: AppColors.accent,
      value: isDark,
      onChanged: (bool value) {
        ref.read(themeModeProvider.notifier).toggleDarkMode(value);
      },
    );
  }
}
