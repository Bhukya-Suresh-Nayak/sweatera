import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sweatera/core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                    'Profile Settings 👤',
                    style: AppTheme.displayMedium.copyWith(
                      foreground: Paint()
                        ..shader = AppTheme.brandGradient.createShader(
                          const Rect.fromLTWH(0, 0, 300, 60),
                        ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Manage your stats, toggle privacy controls, and view workout history records.',
                    style: AppTheme.bodyMedium,
                  ),
                  const Gap(32),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Profile System coming in Phase 8',
                          style: AppTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        Text(
                          'Instagram-like public profile system with activity records, running charts, and privacy switches.',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                            ),
                            child: Text(
                              '🔒 Secure & Privacy-First',
                              style: AppTheme.labelLarge.copyWith(color: AppTheme.accentGreen),
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
          top: 100,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.accentGreen.withOpacity(0.12),
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
