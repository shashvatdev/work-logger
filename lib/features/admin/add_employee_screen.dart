import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/api/api_exception.dart';
import '../../data/repositories/user_repository.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'Employee';
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final repo = UserRepository();
    final result = await repo.createUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case ApiSuccess():
        ref.invalidate(allUsersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Employee added successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      case ApiError(exception: final ex):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ex.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        title: Text(
          'Add Employee',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.sm),

              // ── Avatar illustration ──────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.accent, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Fields Label ─────────────────────────────────────────────
              Text(
                'EMPLOYEE DETAILS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Form Card ────────────────────────────────────────────────
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Name
                    _FormField(
                      child: TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          context,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (v.trim().length < 2) {
                            return 'Minimum 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const AppDivider(indent: 16),
                    // Email
                    _FormField(
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: _inputDecoration(
                          context,
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const AppDivider(indent: 16),
                    // Password
                    _FormField(
                      child: TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          context,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary(context),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) {
                            return 'Minimum 8 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Role Label ───────────────────────────────────────────────
              Text(
                'ROLE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Role Selector ────────────────────────────────────────────
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: AppColors.elevated(context),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary(context)),
                  items: const [
                    DropdownMenuItem(
                      value: 'Employee',
                      child: Text('Employee'),
                    ),
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedRole = v);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Submit Button ────────────────────────────────────────────
              PremiumButton(
                label: 'Add Employee',
                icon: Icons.person_add_rounded,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textSecondary(context)),
      prefixIcon:
          Icon(icon, color: AppColors.textSecondary(context), size: 20),
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Helper wrapper for consistent row padding ────────────────────────────────
class _FormField extends StatelessWidget {
  final Widget child;
  const _FormField({required this.child});

  @override
  Widget build(BuildContext context) => child;
}
