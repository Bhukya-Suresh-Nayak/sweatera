import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sweatera/core/theme/app_theme.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

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
                    'Arena Rankings 🏆',
                    style: AppTheme.displayMedium.copyWith(
                      foreground: Paint()
                        ..shader = AppTheme.brandGradient.createShader(
                          const Rect.fromLTWH(0, 0, 300, 60),
                        ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Compete with athletes globally in pushups, squats, and runs!',
                    style: AppTheme.bodyMedium,
                  ),
                  const Gap(32),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Leaderboard Coming in Phase 7',
                          style: AppTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        Text(
                          'Our backend leaderboard microservice will track streaks, exercise repetitions, and GPS run distances to assign scoring and global rankings.',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryStart.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryStart.withOpacity(0.3)),
                            ),
                            child: Text(
                              '🔥 Scoring System Active Soon',
                              style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryStart),
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
          top: -40,
          right: -50,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primaryStart.withOpacity(0.2),
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
