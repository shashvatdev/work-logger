import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/network_checker.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim().toLowerCase();

    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection. Please check your network and try again.';
        _isLoading = false;
      });
      return;
    }

    final repo = AuthRepository();
    final result = await repo.forgotPassword(email: email);

    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email address.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to Reset Password Screen with email
        context.push('/reset-password', extra: email);
        break;
      case ApiError(exception: final ex):
        setState(() {
          _error = ex.message;
          _isLoading = false;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: BackChevron(),
        ),
        title: Text(
          'Forgot Password',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.02),

                    // Icon / Graphic
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.accentShadow,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Title & Description
                    Text(
                      'Reset Your Password',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter your registered email address and we will send you a 6-digit OTP code to reset your password.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Email Input Field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                            .hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                    ),

                    // Error Message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
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

                    // Send OTP Button
                    PremiumButton(
                      label: 'Send OTP',
                      loading: _isLoading,
                      loadingLabel: 'Sending OTP...',
                      useGradient: true,
                      onPressed: _isLoading ? null : _submit,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Back to Login Link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Back to Sign In'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(context),
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
      ),
    );
  }
}
