import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:sweatera/features/auth/presentation/pages/login_page.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:sweatera/features/auth/presentation/widgets/sweatera_logo.dart';
import 'package:sweatera/routes/app_router.dart';

/// OTP Page — phone number entry + 6-digit OTP verification.
/// Two-step flow: phone entry → OTP code verification.
class OtpPage extends HookConsumerWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  final String phoneNumber;
  final String verificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController(text: phoneNumber);
    final otpController = useTextEditingController();
    final currentVerificationId = useState(verificationId);
    final step = useState<OtpStep>(
      phoneNumber.isEmpty ? OtpStep.phoneEntry : OtpStep.otpEntry,
    );
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final resendCountdown = useState(60);
    final canResend = useState(false);

    final animController = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );
    useEffect(() {
      animController.forward();
      return null;
    }, []);

    // Resend countdown timer
    useEffect(() {
      if (step.value == OtpStep.otpEntry) {
        resendCountdown.value = 60;
        canResend.value = false;
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (resendCountdown.value > 0) {
            resendCountdown.value--;
            return true;
          }
          canResend.value = true;
          return false;
        });
      }
      return null;
    }, [step.value]);

    Future<void> sendOtp() async {
      if (phoneController.text.isEmpty) {
        errorMessage.value = 'Please enter your phone number';
        return;
      }
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      await repo.sendOtp(
        phoneNumber: phoneController.text,
        onCodeSent: (vId) {
          currentVerificationId.value = vId;
          isLoading.value = false;
          step.value = OtpStep.otpEntry;
        },
        onError: (err) {
          isLoading.value = false;
          errorMessage.value = err;
        },
        onAutoVerified: (credential) async {
          isLoading.value = false;
          context.go(AppRoutes.onboarding);
        },
      );
    }

    Future<void> verifyOtp() async {
      if (otpController.text.length < 6) {
        errorMessage.value = 'Please enter the complete 6-digit OTP';
        return;
      }
      isLoading.value = true;
      errorMessage.value = null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyOtp(
        verificationId: currentVerificationId.value,
        smsCode: otpController.text,
      );

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
          _OtpBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: animController, curve: Curves.easeOut),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Gap(40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _OtpBackButton(
                        onTap: () => step.value == OtpStep.otpEntry
                            ? step.value = OtpStep.phoneEntry
                            : context.pop(),
                      ),
                    ),
                    const Gap(32),

                    const SweateraLogo(size: 56),
                    const Gap(16),

                    if (step.value == OtpStep.phoneEntry) ...[
                      Text(
                        'Enter Your\nPhone Number 📱',
                        textAlign: TextAlign.center,
                        style: AppTheme.displayMedium.copyWith(
                          foreground: Paint()
                            ..shader = AppTheme.brandGradient.createShader(
                              const Rect.fromLTWH(0, 0, 280, 60),
                            ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        "We'll send you a one-time verification code",
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium,
                      ),
                      const Gap(36),
                      _OtpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (errorMessage.value != null) ...[
                              _OtpErrorBanner(message: errorMessage.value!),
                              const Gap(16),
                            ],
                            AuthTextField(
                              controller: phoneController,
                              label: 'Phone Number',
                              hint: '+1 234 567 8900',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\s\-()]')),
                              ],
                            ),
                            const Gap(24),
                            AuthButton(
                              label: 'Send OTP',
                              isLoading: isLoading.value,
                              onPressed: sendOtp,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Verify OTP 🔐',
                        textAlign: TextAlign.center,
                        style: AppTheme.displayMedium.copyWith(
                          foreground: Paint()
                            ..shader = AppTheme.brandGradient.createShader(
                              const Rect.fromLTWH(0, 0, 240, 60),
                            ),
                        ),
                      ),
                      const Gap(8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Code sent to '),
                            TextSpan(
                              text: phoneController.text,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primaryStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(36),
                      _OtpCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (errorMessage.value != null) ...[
                              _OtpErrorBanner(message: errorMessage.value!),
                              const Gap(16),
                            ],

                            // PIN input
                            Center(
                              child: Pinput(
                                controller: otpController,
                                length: 6,
                                autofocus: true,
                                onCompleted: (_) => verifyOtp(),
                                defaultPinTheme: PinTheme(
                                  width: 52,
                                  height: 60,
                                  textStyle: AppTheme.headlineMedium,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.border, width: 1),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 52,
                                  height: 60,
                                  textStyle: AppTheme.headlineMedium,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.primaryStart, width: 2),
                                  ),
                                ),
                                submittedPinTheme: PinTheme(
                                  width: 52,
                                  height: 60,
                                  textStyle: AppTheme.headlineMedium.copyWith(
                                    color: AppTheme.primaryStart,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryStart
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.primaryStart
                                            .withOpacity(0.5),
                                        width: 1),
                                  ),
                                ),
                              ),
                            ),

                            const Gap(24),

                            AuthButton(
                              label: 'Verify & Continue',
                              isLoading: isLoading.value,
                              onPressed: verifyOtp,
                            ),

                            const Gap(16),

                            // Resend
                            Center(
                              child: canResend.value
                                  ? GestureDetector(
                                      onTap: sendOtp,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            AppTheme.brandGradient
                                                .createShader(bounds),
                                        child: Text(
                                          'Resend OTP',
                                          style:
                                              AppTheme.labelLarge.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Resend code in ${resendCountdown.value}s',
                                      style: AppTheme.bodyMedium,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Gap(32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum OtpStep { phoneEntry, otpEntry }

class _OtpBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient)),
        Positioned(
          top: -50,
          right: -70,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryEnd.withOpacity(0.2),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.child});
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
            border:
                Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}

class _OtpErrorBanner extends StatelessWidget {
  const _OtpErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.accentRed.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.accentRed, size: 18),
          const Gap(10),
          Expanded(
            child: Text(message,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}

class _OtpBackButton extends StatelessWidget {
  const _OtpBackButton({required this.onTap});
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
