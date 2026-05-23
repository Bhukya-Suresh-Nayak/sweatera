import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/leaderboard/domain/models/leaderboard_user_model.dart';
import 'package:sweatera/features/leaderboard/presentation/providers/leaderboard_provider.dart';

/// LeaderboardPage — Real-time multi-level location fitness scoreboard.
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  // Active location segment level
  String _selectedLevel = 'global';

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(leaderboardProvider(_selectedLevel));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cybernetic Background Glow ─────────────────────────────────────────
          _BackgroundGlow(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Title & Descriptions ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arena Rankings 🏆',
                        style: AppTheme.displayMedium.copyWith(
                          foreground: Paint()
                            ..shader = AppTheme.brandGradient.createShader(
                              const Rect.fromLTWH(0, 0, 300, 60),
                            ),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'Compete with global and local athletes in pushups, squats, and running.',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Interactive Segment Tab Switcher ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildLocationSwitcher(),
                ),
                const Gap(24),

                // ── Active Podium & Rankings Scoreboard ─────────────────────────────
                Expanded(
                  child: athletesAsync.when(
                    data: (athletes) {
                      if (athletes.isEmpty) {
                        return const Center(child: Text('No competitors in this tier yet.', style: TextStyle(color: AppTheme.textMuted)));
                      }

                      final podiumAthletes = athletes.take(3).toList();
                      final listAthletes = athletes.skip(3).toList();

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // 1. Top 3 Podium Displays
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildTopThreePodium(podiumAthletes),
                            ),
                          ),
                          const SliverToBoxAdapter(child: Gap(28)),

                          // 2. Scrollable rankings list (ranks 4 and onwards)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final athlete = listAthletes[index];
                                  final rank = index + 4; // Podium takes ranks 1, 2, 3
                                  return _buildRankRow(athlete, rank);
                                },
                                childCount: listAthletes.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: Gap(100)),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Center(child: Text('Scoreboard loading failed: $e', style: const TextStyle(color: AppTheme.accentRed))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSwitcher() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSwitcherChip(label: 'Global 🌍', level: 'global'),
                _buildSwitcherChip(label: 'National 🏳️', level: 'national'),
                _buildSwitcherChip(label: 'State 🏔️', level: 'state'),
                _buildSwitcherChip(label: 'District 📍', level: 'district'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitcherChip({required String label, required String level}) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppTheme.brandGradient : null,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTopThreePodium(List<LeaderboardUserModel> athletes) {
    if (athletes.isEmpty) return const SizedBox();

    // Map gold, silver, bronze indexes
    final LeaderboardUserModel? first = athletes.isNotEmpty ? athletes[0] : null;
    final LeaderboardUserModel? second = athletes.length > 1 ? athletes[1] : null;
    final LeaderboardUserModel? third = athletes.length > 2 ? athletes[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🥈 RANK 2
        if (second != null) ...[
          Expanded(
            child: _buildPodiumColumn(
              athlete: second,
              rank: 2,
              height: 145,
              color: AppTheme.primaryMid,
              trophyIcon: Icons.emoji_events_rounded,
              trophyColor: Colors.grey.shade400,
            ),
          ),
          const Gap(12),
        ],

        // 🥇 RANK 1
        if (first != null) ...[
          Expanded(
            child: _buildPodiumColumn(
              athlete: first,
              rank: 1,
              height: 175,
              color: AppTheme.primaryStart,
              trophyIcon: Icons.emoji_events_rounded,
              trophyColor: const Color(0xFFFFD700), // Gold
              isCenter: true,
            ),
          ),
          const Gap(12),
        ],

        // 🥉 RANK 3
        if (third != null) ...[
          Expanded(
            child: _buildPodiumColumn(
              athlete: third,
              rank: 3,
              height: 125,
              color: AppTheme.primaryEnd,
              trophyIcon: Icons.emoji_events_rounded,
              trophyColor: const Color(0xFFCD7F32), // Bronze
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardUserModel athlete,
    required int rank,
    required double height,
    required Color color,
    required IconData trophyIcon,
    required Color trophyColor,
    bool isCenter = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing trophy/rank indicator
        Icon(trophyIcon, color: trophyColor, size: isCenter ? 36 : 28),
        const Gap(8),

        // Glassmorphic podium block
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isCenter ? 0.06 : 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCenter ? AppTheme.primaryStart.withOpacity(0.3) : Colors.white.withOpacity(0.08),
                  width: isCenter ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: isCenter ? 24 : 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Text(
                          athlete.username.substring(0, 1).toUpperCase(),
                          style: AppTheme.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        athlete.username,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: isCenter ? FontWeight.w900 : FontWeight.bold,
                          fontSize: isCenter ? 13 : 11,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${athlete.totalScore}',
                        style: AppTheme.headlineMedium.copyWith(
                          fontSize: isCenter ? 18 : 14,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      Text(
                        'PTS',
                        style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardUserModel athlete, int rank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 32,
                  child: Text(
                    '#$rank',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Mini Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryEnd.withOpacity(0.1),
                  child: Text(
                    athlete.username.substring(0, 1).toUpperCase(),
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryEnd, fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(14),

                // Username & Streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.username,
                        style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentOrange, size: 12),
                          const Gap(4),
                          Text(
                            '${athlete.streakCount} day streak',
                            style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${athlete.totalScore} PTS',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.primaryStart,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
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

// ── Background Glow Widget ───────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
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
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryStart.withOpacity(0.18),
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
