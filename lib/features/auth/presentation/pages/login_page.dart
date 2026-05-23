import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:sweatera/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/sweatera_logo.dart';
import 'package:sweatera/routes/app_router.dart';

/// Login Page — premium dark glassmorphism design.
/// Supports Email/Password, Google Sign-In, and Phone OTP flows.
class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final isPasswordVisible = useState(false);

    // Entrance animation controller
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    final fadeAnim = useMemoized(
      () => CurvedAnimation(parent: animController, curve: Curves.easeOut),
      [animController],
    );
    final slideAnim = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animController,
        curve: Curves.easeOutCubic,
      )),
      [animController],
    );

    useEffect(() {
      animController.forward();
      return null;
    }, []);

    Future<void> handleEmailLogin() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithEmail(
        email: emailController.text,
        password: passwordController.text,
      );

      isLoading.value = false;
      result.when(
        success: (_) => context.go(AppRoutes.dashboard),
        failure: (msg) => errorMessage.value = msg,
      );
    }

    Future<void> handleGoogleLogin() async {
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();

      isLoading.value = false;
      result.when(
        success: (_) => context.go(AppRoutes.dashboard),
        failure: (msg) => errorMessage.value = msg,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // ── Animated Background ───────────────────────────────────────────
          _BackgroundGlow(),

          // ── Main Content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Gap(48),

                        // Logo + Branding
                        const SweateraLogo(),
                        const Gap(12),
                        Text(
                          'Welcome back,\nChampion 💪',
                          textAlign: TextAlign.center,
                          style: AppTheme.displayMedium.copyWith(
                            foreground: Paint()
                              ..shader = AppTheme.brandGradient.createShader(
                                const Rect.fromLTWH(0, 0, 300, 60),
                              ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Sign in to continue your fitness journey',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium,
                        ),

                        const Gap(40),

                        // ── Glass Card ────────────────────────────────────────
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error Banner
                              if (errorMessage.value != null) ...[
                                _ErrorBanner(message: errorMessage.value!),
                                const Gap(20),
                              ],

                              // Email Field
                              AuthTextField(
                                controller: emailController,
                                label: 'Email address',
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16),

                              // Password Field
                              AuthTextField(
                                controller: passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                obscureText: !isPasswordVisible.value,
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => isPasswordVisible.value =
                                      !isPasswordVisible.value,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _showForgotPasswordSheet(context, ref),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.primaryStart,
                                    ),
                                  ),
                                ),
                              ),
                              const Gap(8),

                              // Sign In Button
                              AuthButton(
                                label: 'Sign In',
                                isLoading: isLoading.value,
                                onPressed: handleEmailLogin,
                              ),

                              const Gap(24),

                              // Divider
                              _OrDivider(),

                              const Gap(24),

                              // Google Sign-In
                              GoogleSignInButton(
                                isLoading: isLoading.value,
                                onPressed: handleGoogleLogin,
                              ),

                              const Gap(16),

                              // Phone OTP
                              OutlinedButton.icon(
                                onPressed: isLoading.value
                                    ? null
                                    : () => context.push(AppRoutes.otp,
                                        extra: ''),
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                                label: Text(
                                  'Continue with Phone',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppTheme.border, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  minimumSize: const Size(double.infinity, 56),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(28),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.signup),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppTheme.brandGradient
                                        .createShader(bounds),
                                child: Text(
                                  'Create Account',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Gap(32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet for password reset
  void _showForgotPasswordSheet(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(20),
            Text('Reset Password', style: AppTheme.headlineMedium),
            const Gap(8),
            Text(
              'Enter your email and we\'ll send you a reset link.',
              style: AppTheme.bodyMedium,
            ),
            const Gap(24),
            AuthTextField(
              controller: emailController,
              label: 'Email address',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const Gap(20),
            AuthButton(
              label: 'Send Reset Link',
              onPressed: () async {
                if (emailController.text.isEmpty) return;
                final repo = ref.read(authRepositoryProvider);
                await repo.sendPasswordResetEmail(emailController.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        // Top violet glow
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryStart.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom cyan glow
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryEnd.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.accentRed,
            size: 18,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.border),
        ),
      ],
    );
  }
}

// Extension to handle AuthResult pattern matching
extension AuthResultX on AuthResult {
  void when({
    required void Function(dynamic user) success,
    required void Function(String message) failure,
  }) {
    if (this is AuthSuccess) {
      success((this as AuthSuccess).user);
    } else if (this is AuthFailure) {
      failure((this as AuthFailure).message);
    }
  }
}
