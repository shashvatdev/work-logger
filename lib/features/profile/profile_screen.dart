import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/app_providers.dart';
import '../../core/api/token_storage.dart';
import '../../core/api/api_exception.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isUpdatingName = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameCtrl.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _updateName() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == user.name) return;

    setState(() => _isUpdatingName = true);

    final repo = UserRepository();
    final result = await repo.updateMe(name: name);

    if (!mounted) return;
    setState(() => _isUpdatingName = false);

    switch (result) {
      case ApiSuccess(data: final updatedUser):
        ref.read(currentUserProvider.notifier).state = updatedUser;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully'), backgroundColor: AppColors.success),
        );
        break;
      case ApiError(exception: final ex):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ex.message), backgroundColor: AppColors.error),
        );
        break;
    }
  }

  void _changePassword() async {
    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    final repo = UserRepository();
    final user = ref.read(currentUserProvider);
    final result = await repo.updateMe(
      name: user?.name ?? '',
      currentPassword: current,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    switch (result) {
      case ApiSuccess():
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppColors.success),
        );
        break;
      case ApiError(exception: final ex):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ex.message), backgroundColor: AppColors.error),
        );
        break;
    }
  }

  void _logout() async {
    await AuthRepository().logout();
    await TokenStorage.clearAll();
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(allProjectsProvider);
    ref.invalidate(myProjectsProvider);
    ref.invalidate(todayLogProvider);
    ref.invalidate(allUsersProvider);
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();

    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const BackChevron(),
                    const Spacer(),
                    StatusDot(active: user.isActive, size: 10),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: user.isActive ? AppColors.success : AppColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  InitialsAvatar(
                    name: user.name,
                    radius: 40,
                    showRing: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ChipLabel(
                    label: user.roleDisplay,
                    color: user.isSuperAdmin
                        ? AppColors.warning
                        : (user.isAdmin ? AppColors.accent : AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDIT PROFILE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary(context)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SecondaryButton(
                            label: _isUpdatingName ? 'Updating...' : 'Update Name',
                            icon: Icons.check,
                            onPressed: _isUpdatingName ? null : _updateName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'SECURITY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SurfaceCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _currentPasswordCtrl,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              hintText: 'Current Password',
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary(context)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary(context)),
                                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _newPasswordCtrl,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              hintText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary(context)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary(context)),
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _confirmPasswordCtrl,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Confirm New Password',
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary(context)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary(context)),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SecondaryButton(
                            label: _isChangingPassword ? 'Changing...' : 'Change Password',
                            icon: Icons.security,
                            onPressed: _isChangingPassword ? null : _changePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PremiumButton(
                      label: 'Logout',
                      icon: Icons.logout,
                      backgroundColor: AppColors.error,
                      useGradient: false,
                      onPressed: _logout,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
