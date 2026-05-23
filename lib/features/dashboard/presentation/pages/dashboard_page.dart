import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/profile/data/models/user_model.dart';
import 'package:sweatera/features/profile/data/repositories/user_profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sweatera/routes/app_router.dart';
/// DashboardPage — The visual cornerstone of the SweatEra athletic experience.
/// Implements beautiful glowing glass cards, streak trackers, and workout progress grids.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _DashboardBackgroundGlow(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Dynamic Top App Bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(profileAsync: profileAsync),
                        const Gap(24),
                        _SearchBar(),
                      ],
                    ),
                  ),
                ),

                // ── Welcome & Streak Banner ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _StreakBanner(profileAsync: profileAsync),
                  ),
                ),

                // ── Quick Workouts Header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                    child: Text(
                      'Start Training ⚡',
                      style: AppTheme.headlineMedium,
                    ),
                  ),
                ),

                // ── Quick Start CTAs ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _QuickStartCTAs(),
                  ),
                ),

                // ── Exercise Stats Header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 12),
                    child: Text(
                      'Your Statistics 📊',
                      style: AppTheme.headlineMedium,
                    ),
                  ),
                ),

                // ── Stats Cards Grid ─────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _StatsGrid(profileAsync: profileAsync),
                ),

                // ── Weekly Progress & Metrics ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: _WeeklyProgressCard(),
                  ),
                ),

                // Extra padding to avoid overlapping the glass bottom navigation bar
                const SliverToBoxAdapter(child: Gap(100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Component ─────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profileAsync});
  final AsyncValue<UserModel?> profileAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SweatEra',
              style: AppTheme.headlineMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryStart,
                letterSpacing: 0.5,
              ),
            ),
            const Gap(4),
            profileAsync.when(
              data: (profile) {
                final name = profile?.username ?? 'Champion';
                return Text(
                  'Hello, $name! 👋',
                  style: AppTheme.displayMedium.copyWith(fontSize: 26),
                );
              },
              loading: () => Text('Loading athlete...', style: AppTheme.displayMedium.copyWith(fontSize: 26)),
              error: (_, __) => Text('Hello, Champion! 👋', style: AppTheme.displayMedium.copyWith(fontSize: 26)),
            ),
          ],
        ),

        // User Avatar Mockup
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryStart, width: 2),
            gradient: AppTheme.brandGradient,
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

// ── Search Bar Component ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          child: TextField(
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search workouts, exercises, diets...',
              hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Streak Banner Component ──────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.profileAsync});
  final AsyncValue<UserModel?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final streakCount = profileAsync.valueOrNull?.streakCount ?? 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Glowing flame icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentOrange.withOpacity(0.12),
                  border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.local_fire_department_rounded, color: AppTheme.accentOrange, size: 32),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streakCount Day Streak!',
                      style: AppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      streakCount > 0
                          ? 'Outstanding consistency! Keep pushing!'
                          : 'Start a workout today to initiate your streak!',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Start Workouts Component ────────────────────────────────────────────

class _QuickStartCTAs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStartButton(
            label: 'Pose AI Poses',
            icon: Icons.camera_front_rounded,
            gradient: AppTheme.brandGradient,
            onPressed: () {
              context.push(AppRoutes.workouts);
            },
          ),
        ),
        const Gap(14),
        Expanded(
          child: _QuickStartButton(
            label: 'GPS Run Tracker',
            icon: Icons.directions_run_rounded,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryMid, AppTheme.accentGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Run tracker... (Phase 5)')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickStartButton extends StatelessWidget {
  const _QuickStartButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const Gap(10),
                Text(
                  label,
                  style: AppTheme.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats Cards Grid Component ────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profileAsync});
  final AsyncValue<UserModel?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final user = profileAsync.valueOrNull;

    final pushups = user?.totalPushups ?? 0;
    final squats = user?.totalSquats ?? 0;
    final jumps = user?.totalJumps ?? 0;
    final distance = user?.totalRunningDistance ?? 0.0;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.35,
      ),
      delegate: SliverChildListDelegate([
        _StatsCard(
          title: 'Pushups',
          value: '$pushups reps',
          icon: Icons.fitness_center_rounded,
          color: AppTheme.primaryStart,
        ),
        _StatsCard(
          title: 'Squats',
          value: '$squats reps',
          icon: Icons.accessibility_new_rounded,
          color: AppTheme.primaryMid,
        ),
        _StatsCard(
          title: 'Jumps',
          value: '$jumps reps',
          icon: Icons.bolt_rounded,
          color: AppTheme.primaryEnd,
        ),
        _StatsCard(
          title: 'Running',
          value: '${distance.toStringAsFixed(1)} km',
          icon: Icons.map_rounded,
          color: AppTheme.accentGreen,
        ),
      ]),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.textMuted),
                  ),
                  Icon(icon, color: color, size: 22),
                ],
              ),
              Text(
                value,
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekly Progress Component ────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly Progress 📈', style: AppTheme.headlineMedium),
              const Gap(6),
              Text(
                'Keep up the consistency to complete your weekly activity ring!',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: 0.68,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryStart),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '68%',
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'done',
                            style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(24),
                  // Details list
                  Expanded(
                    child: Column(
                      children: [
                        _ProgressDetailRow(
                          label: 'Active Time',
                          value: '2.4 hrs / 4.0',
                          color: AppTheme.primaryStart,
                        ),
                        const Gap(10),
                        _ProgressDetailRow(
                          label: 'Calories Burned',
                          value: '840 kcal / 1200',
                          color: AppTheme.primaryMid,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDetailRow extends StatelessWidget {
  const _ProgressDetailRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const Gap(8),
            Text(label, style: AppTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ── Background Glow ──────────────────────────────────────────────────────────

class _DashboardBackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryStart.withOpacity(0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGreen.withOpacity(0.12),
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
