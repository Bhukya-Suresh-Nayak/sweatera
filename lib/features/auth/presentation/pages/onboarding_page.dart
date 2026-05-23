import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_button.dart';
import 'package:sweatera/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:sweatera/routes/app_router.dart';

/// Onboarding Page — collects username, gender, weight, and age
/// after a new user registers. Saves to Firestore via UserRepository.
class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final weightController = useTextEditingController();
    final ageController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final selectedGender = useState<String?>(null);
    final isLoading = useState(false);
    final currentStep = useState(0);

    final animController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    useEffect(() {
      animController.forward();
      return null;
    }, []);

    Future<void> completeOnboarding() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedGender.value == null) return;

      isLoading.value = true;
      // TODO: save to Firestore via UserRepository
      await Future.delayed(const Duration(milliseconds: 800));
      isLoading.value = false;

      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _OnboardingBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: animController, curve: Curves.easeOut),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(40),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            // Animated icon
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryStart.withOpacity(0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const Gap(20),
                            Text(
                              'Complete Your\nProfile ✨',
                              textAlign: TextAlign.center,
                              style: AppTheme.displayMedium.copyWith(
                                foreground: Paint()
                                  ..shader = AppTheme.brandGradient
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 280, 60)),
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'Help us personalize your fitness experience',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const Gap(36),

                      // ── Profile Form Card ─────────────────────────────────
                      _OnboardingCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Username
                            _SectionLabel(label: 'Username', icon: Icons.alternate_email_rounded),
                            const Gap(10),
                            AuthTextField(
                              controller: usernameController,
                              label: 'Choose a username',
                              hint: 'e.g. fitwarrior_99',
                              prefixIcon: Icons.alternate_email_rounded,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9_\.]')),
                                LengthLimitingTextInputFormatter(24),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Username is required';
                                }
                                if (v.length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                            ),

                            const Gap(24),

                            // Gender
                            _SectionLabel(label: 'Gender', icon: Icons.wc_rounded),
                            const Gap(10),
                            _GenderSelector(
                              selected: selectedGender.value,
                              onSelected: (g) => selectedGender.value = g,
                            ),

                            const Gap(24),

                            // Weight & Age (side by side)
                            _SectionLabel(label: 'Body Stats', icon: Icons.monitor_weight_outlined),
                            const Gap(10),
                            Row(
                              children: [
                                Expanded(
                                  child: AuthTextField(
                                    controller: weightController,
                                    label: 'Weight (kg)',
                                    hint: '70',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    prefixIcon: Icons.monitor_weight_outlined,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9\.]')),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      final val = double.tryParse(v);
                                      if (val == null || val < 20 || val > 300) {
                                        return 'Invalid weight';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: AuthTextField(
                                    controller: ageController,
                                    label: 'Age',
                                    hint: '25',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.cake_outlined,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      final val = int.tryParse(v);
                                      if (val == null || val < 10 || val > 100) {
                                        return 'Invalid age';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const Gap(32),

                            AuthButton(
                              label: "Let's Go! 🚀",
                              isLoading: isLoading.value,
                              onPressed: completeOnboarding,
                            ),
                          ],
                        ),
                      ),

                      const Gap(32),
                    ],
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

class _OnboardingBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
      Positioned(
        top: -80,
        left: -60,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppTheme.accentGreen.withOpacity(0.12),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.child});
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryStart, size: 16),
        const Gap(8),
        Text(
          label,
          style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selected,
    required this.onSelected,
  });
  final String? selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GenderChip(
          label: 'Male',
          icon: Icons.male_rounded,
          isSelected: selected == 'male',
          onTap: () => onSelected('male'),
        ),
        const Gap(12),
        _GenderChip(
          label: 'Female',
          icon: Icons.female_rounded,
          isSelected: selected == 'female',
          onTap: () => onSelected('female'),
        ),
        const Gap(12),
        _GenderChip(
          label: 'Other',
          icon: Icons.transgender_rounded,
          isSelected: selected == 'other',
          onTap: () => onSelected('other'),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isSelected ? AppTheme.brandGradient : null,
            color: isSelected ? null : AppTheme.surfaceElevated,
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryStart.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textMuted,
                size: 22,
              ),
              const Gap(4),
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
