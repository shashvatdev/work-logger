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

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accent.withOpacity(0.05),
              AppColors.background(context),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.1),

                  // ── Logo mark ────────────────────────────────────────────
                  StaggeredItem(
                    index: 0,
                    baseDelay: Duration.zero,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.accentShadow,
                      ),
                      child: const Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Heading ──────────────────────────────────────────────
                  StaggeredItem(
                    index: 1,
                    baseDelay: const Duration(milliseconds: 120),
                    child: Text(
                      'Track It',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaggeredItem(
                    index: 2,
                    baseDelay: const Duration(milliseconds: 180),
                    child: Text(
                      'Track your work. Every day.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary(context),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Email ────────────────────────────────────────────────
                  StaggeredItem(
                    index: 3,
                    baseDelay: const Duration(milliseconds: 260),
                    child: Column(
                      children: [
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.textSecondary(context)),
                        ),
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
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              color: AppColors.textSecondary(context)),
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
                    ]),
                  ),

                  // ── Error ────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, -0.2), end: Offset.zero)
                          .animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _error != null
                        ? Padding(
                            key: const ValueKey('error'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.error),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no_error')),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Sign In button ───────────────────────────────────────
                  StaggeredItem(
                    index: 4,
                    baseDelay: const Duration(milliseconds: 340),
                    child: PremiumButton(
                      label: 'Sign In',
                      loading: _loading,
                      useGradient: true,
                      onPressed: _signIn,
                    ),
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

                    SizedBox(height: size.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

