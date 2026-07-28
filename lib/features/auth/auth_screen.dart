import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';

import '../../data/repositories/auth_repository.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';
import 'change_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter email and password.';
        _loading = false;
      });
      return;
    }

    final repo = AuthRepository();
    final result = await repo.login(email: email, password: password);

    if (!mounted) return;

    switch (result) {
      case ApiSuccess(data: final data):
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        ref.read(currentUserProvider.notifier).state = user;
        
        // Invalidate caching providers to ensure fresh data
        ref.invalidate(allProjectsProvider);
        ref.invalidate(myProjectsProvider);
        ref.invalidate(todayLogProvider);
        ref.invalidate(allUsersProvider);
        
        setState(() => _loading = false);
        context.go(user.isAdmin ? '/admin/employees' : '/home');
        break;
      case ApiError(exception: final ex):
        setState(() {
          _error = ex.message;
          _loading = false;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.1),

                    // ── Logo mark ────────────────────────────────────────────
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Heading ──────────────────────────────────────────────
                    Text(
                      'WorkNote',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your daily work journal.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Email ────────────────────────────────────────────────
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(hintText: 'Email'),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Password ─────────────────────────────────────────────
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signIn(),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // ── Error ────────────────────────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: _error != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Sign In button ───────────────────────────────────────
                    PremiumButton(
                      label: 'Sign In',
                      loading: _loading,
                      onPressed: _signIn,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Change Password link ─────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Change Password?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Demo accounts shortcuts ──────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Quick Demo Accounts',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              _demoChip(context, 'Super Admin', 'admin@gmail.com'),
                              _demoChip(context, 'Employee 1', 'employee1@gmail.com'),
                              _demoChip(context, 'Employee 2', 'employee2@gmail.com'),
                              _demoChip(context, 'Employee 3', 'employee3@gmail.com'),
                              _demoChip(context, 'Employee 4', 'employee4@gmail.com'),
                              _demoChip(context, 'Employee 5', 'employee5@gmail.com'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(BuildContext context, String name, String email, {String password = '12345'}) {
    return InkWell(
      onTap: () {
        _emailCtrl.text = email;
        _passCtrl.text = password;
        setState(() => _error = null);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          '$name ($email)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
