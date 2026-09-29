import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/network_checker.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  int _resendTimerSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() => _resendTimerSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() => _resendTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_resendTimerSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection.';
        _isResending = false;
      });
      return;
    }

    final repo = AuthRepository();
    final result = await repo.forgotPassword(email: widget.email);

    if (!mounted) return;

    setState(() => _isResending = false);

    switch (result) {
      case ApiSuccess():
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh OTP has been sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case ApiError(exception: final ex):
        setState(() => _error = ex.message);
        break;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

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
    final result = await repo.resetPassword(
      email: widget.email,
      otp: _otpCtrl.text.trim(),
      newPassword: _newPassCtrl.text,
    );

    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        setState(() => _isLoading = false);
        _showSuccessDialog();
        break;
      case ApiError(exception: final ex):
        setState(() {
          _error = ex.message;
          _isLoading = false;
        });
        break;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Password Reset',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Your password has been successfully reset. You can now log in with your new password.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              label: 'Proceed to Sign In',
              useGradient: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/auth');
              },
            ),
          ),
        ],
      ),
    );
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
          'Reset Password',
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
                    SizedBox(height: size.height * 0.01),

                    // Email badge indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(context),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Info text
                    Text(
                      'Enter OTP & New Password',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please enter the 6-digit verification code sent to your email and set your new password.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary(context),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // OTP Field
                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 8.0,
                            fontWeight: FontWeight.w700,
                          ),
                      decoration: InputDecoration(
                        labelText: '6-Digit OTP Code',
                        hintText: '000000',
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'OTP is required';
                        }
                        if (value.trim().length != 6) {
                          return 'Enter exactly 6 digits';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                    ),

                    // Resend OTP section
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resendTimerSeconds == 0 && !_isResending
                            ? _resendOtp
                            : null,
                        child: Text(
                          _resendTimerSeconds > 0
                              ? 'Resend OTP in ${_resendTimerSeconds}s'
                              : (_isResending ? 'Resending...' : 'Resend OTP'),
                          style: TextStyle(
                            fontSize: 13,
                            color: _resendTimerSeconds > 0
                                ? AppColors.textSecondary(context)
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // New Password Field
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary(context),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary(context),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.textSecondary(context),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary(context),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
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

                    // Submit Button
                    PremiumButton(
                      label: 'Reset Password',
                      loading: _isLoading,
                      loadingLabel: 'Resetting Password...',
                      useGradient: true,
                      onPressed: _isLoading ? null : _submit,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Back to Login Link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/auth'),
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
