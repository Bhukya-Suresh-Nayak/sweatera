import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sweatera/core/theme/app_theme.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _BackgroundGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(20),
                  Text(
                    'AI Nutritionist 🥦',
                    style: AppTheme.displayMedium.copyWith(
                      foreground: Paint()
                        ..shader = AppTheme.brandGradient.createShader(
                          const Rect.fromLTWH(0, 0, 300, 60),
                        ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Scan food pictures for instant calorie, macronutrient, and healthy option tables.',
                    style: AppTheme.bodyMedium,
                  ),
                  const Gap(32),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Food Scanner coming in Phase 6',
                          style: AppTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        Text(
                          'Upload an image of your meal, and our Gemini-powered AI service will instantly calculate calories, protein, carbs, and fats in a clean UI table format.',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEnd.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryEnd.withOpacity(0.3)),
                            ),
                            child: Text(
                              '🤖 Gemini-Powered Analysis',
                              style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryEnd),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
        Positioned(
          bottom: -40,
          left: -50,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryEnd.withOpacity(0.18),
                Colors.transparent,
              ]),
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
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}
