import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/user_repository.dart';
import '../attendance/data/models/assigned_office.dart';

// ─── Provider: load all geofence offices ─────────────────────────────────────
final _officesProvider = FutureProvider<List<AssignedOffice>>((ref) async {
  try {
    final resp = await ApiClient.instance.get('/geofence');
    if (resp.statusCode == 200) {
      final data = resp.data;
      List rawList = [];
      if (data is List) rawList = data;
      else if (data is Map) rawList = data['zones'] ?? data['offices'] ?? data['data'] ?? [];
      
      return rawList
          .map((o) => AssignedOffice.fromJson(o as Map<String, dynamic>))
          .toList();
    }
    return <AssignedOffice>[];
  } on DioException {
    return <AssignedOffice>[];
  }
});

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

  /// null = "None" (no office assigned)
  String? _selectedOfficeId;

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
      assignedOfficeId: _selectedOfficeId,
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
    final officesAsync = ref.watch(_officesProvider);

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
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Fields Label ─────────────────────────────────────────────
              Text(
                'EMPLOYEE DETAILS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Role Selector ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'Employee'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'Employee'
                              ? AppColors.accent
                              : AppColors.elevated(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: _selectedRole == 'Employee'
                              ? AppColors.accentShadow
                              : null,
                          border: _selectedRole != 'Employee'
                              ? Border.all(
                                  color: AppColors.separator(context),
                                  width: 0.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Employee',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: _selectedRole == 'Employee'
                                          ? Colors.white
                                          : AppColors.textPrimary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'Admin'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'Admin'
                              ? AppColors.accent
                              : AppColors.elevated(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: _selectedRole == 'Admin'
                              ? AppColors.accentShadow
                              : null,
                          border: _selectedRole != 'Admin'
                              ? Border.all(
                                  color: AppColors.separator(context),
                                  width: 0.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Admin',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: _selectedRole == 'Admin'
                                          ? Colors.white
                                          : AppColors.textPrimary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Assigned Office Label ────────────────────────────────────
              Text(
                'ASSIGNED OFFICE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Office Dropdown Card ─────────────────────────────────────
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: officesAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.business_outlined,
                            size: 20,
                            color: AppColors.textSecondary(context)),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Loading offices…',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.business_outlined,
                            size: 20,
                            color: AppColors.textSecondary(context)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Could not load offices',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  data: (offices) {
                    // Build items: "None" sentinel + all active offices
                    final activeOffices =
                        offices.where((o) => o.isActive).toList();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 2),
                      child: DropdownButtonFormField<String?>(
                        value: _selectedOfficeId,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary(context), size: 22),
                        dropdownColor: AppColors.elevated(context),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.business_outlined,
                            color: AppColors.textSecondary(context),
                            size: 20,
                          ),
                          labelText: 'Assigned Office (Optional)',
                          labelStyle: TextStyle(
                              color: AppColors.textSecondary(context)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 14),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'None',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AppColors.textSecondary(context)),
                            ),
                          ),
                          ...activeOffices.map(
                            (office) => DropdownMenuItem<String?>(
                              value: office.id,
                              child: Text(
                                office.name,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedOfficeId = value),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Submit Button ────────────────────────────────────────────
              PremiumButton(
                label: 'Add Employee',
                icon: Icons.person_add_rounded,
                loading: _loading,
                useGradient: true,
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
