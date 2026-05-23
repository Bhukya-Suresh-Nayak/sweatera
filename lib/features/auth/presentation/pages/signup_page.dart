import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:sweatera/features/auth/presentation/pages/login_page.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:sweatera/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/sweatera_logo.dart';
import 'package:sweatera/routes/app_router.dart';

/// Sign Up Page — premium dark design with animated entrance.
class SignupPage extends HookConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final isPasswordVisible = useState(false);
    final isConfirmPasswordVisible = useState(false);

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
      ).animate(
          CurvedAnimation(parent: animController, curve: Curves.easeOutCubic)),
      [animController],
    );

    useEffect(() {
      animController.forward();
      return null;
    }, []);

    Future<void> handleSignup() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signUpWithEmail(
        email: emailController.text,
        password: passwordController.text,
      );

      isLoading.value = false;
      result.when(
        success: (_) => context.go(AppRoutes.onboarding),
        failure: (msg) => errorMessage.value = msg,
      );
    }

    Future<void> handleGoogleSignup() async {
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();

      isLoading.value = false;
      result.when(
        success: (_) => context.go(AppRoutes.onboarding),
        failure: (msg) => errorMessage.value = msg,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _SignupBackground(),
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
                        const Gap(40),
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BackButton(onTap: () => context.pop()),
                        ),
                        const Gap(24),

                        const SweateraLogo(size: 56),
                        const Gap(12),
                        Text(
                          'Start Your\nFitness Journey 🔥',
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
                          'Create your account and start tracking today',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium,
                        ),
                        const Gap(36),

                        // ── Glass Card ──────────────────────────────────────
                        _SignupCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (errorMessage.value != null) ...[
                                _SignupErrorBanner(
                                    message: errorMessage.value!),
                                const Gap(20),
                              ],

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

                              AuthTextField(
                                controller: passwordController,
                                label: 'Password',
                                hint: 'At least 6 characters',
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
                                  if (v == null || v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(16),

                              AuthTextField(
                                controller: confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                obscureText: !isConfirmPasswordVisible.value,
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isConfirmPasswordVisible.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      isConfirmPasswordVisible.value =
                                          !isConfirmPasswordVisible.value,
                                ),
                                validator: (v) {
                                  if (v != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(24),

                              AuthButton(
                                label: 'Create Account',
                                isLoading: isLoading.value,
                                onPressed: handleSignup,
                              ),

                              const Gap(24),

                              _OrDivider(),

                              const Gap(24),

                              GoogleSignInButton(
                                isLoading: isLoading.value,
                                onPressed: handleGoogleSignup,
                                label: 'Sign up with Google',
                              ),
                            ],
                          ),
                        ),

                        const Gap(28),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppTheme.brandGradient
                                        .createShader(bounds),
                                child: Text(
                                  'Sign In',
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
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SignupBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
        Positioned(
          top: -60,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryMid.withOpacity(0.22),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryEnd.withOpacity(0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.child});
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
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}

class _SignupErrorBanner extends StatelessWidget {
  const _SignupErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.accentRed.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.accentRed, size: 18),
          const Gap(10),
          Expanded(
            child: Text(message,
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.accentRed)),
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
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or sign up with',
              style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary, size: 18),
      ),
    );
  }
}
