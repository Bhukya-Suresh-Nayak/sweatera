import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/profile/data/models/user_model.dart';
import 'package:sweatera/features/profile/data/repositories/user_profile_provider.dart';
import 'package:sweatera/features/profile/data/repositories/user_repository_provider.dart';

/// ProfilePage — Premium privacy-first athlete profile dashboard.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _RiGridItem {
  final int count;
  _RiGridItem(this.count);
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Local state to simulate how other public athletes view this profile
  bool _isPreviewMode = false;

  Future<void> _updatePrivacyField(String fieldName, bool value) async {
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (userProfile == null) return;

    // Show dynamic progress snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating privacy controls...'),
        duration: Duration(milliseconds: 400),
      ),
    );

    try {
      UserModel updatedProfile;
      if (fieldName == 'isPrivate') {
        updatedProfile = userProfile.copyWith(isPrivate: value);
      } else if (fieldName == 'showHeightToPublic') {
        updatedProfile = userProfile.copyWith(showHeightToPublic: value);
      } else {
        updatedProfile = userProfile.copyWith(showWeightToPublic: value);
      }

      await ref.read(userRepositoryProvider).updateUserProfile(updatedProfile);
      ref.invalidate(userProfileProvider); // Push new states
    } catch (e) {
      debugPrint('Update privacy failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update privacy settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cybernetic Background Glow ─────────────────────────────────────────
          _BackgroundGlow(),

          SafeArea(
            child: userProfileAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(child: Text('Profile not found. Please complete onboarding.'));
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title & Preview Controller ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Athlete Profile 👤',
                            style: AppTheme.displayMedium.copyWith(
                              foreground: Paint()
                                ..shader = AppTheme.brandGradient.createShader(
                                  const Rect.fromLTWH(0, 0, 300, 60),
                                ),
                            ),
                          ),
                          // View Preview Mode switch
                          _buildPreviewToggle(),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        _isPreviewMode
                            ? 'Previewing your public profile as viewed by other members in global rankings.'
                            : 'Configure your privacy settings, check cumulative metrics, and consistency graphs.',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                      ),
                      const Gap(24),

                      // ── 1. User Header card ───────────────────────────────────────
                      _buildHeaderCard(user),
                      const Gap(20),

                      // ── 2. Stature metrics grid (Height/Weight Lockups) ───────────
                      _buildStatureGrid(user),
                      const Gap(20),

                      // ── 3. Privacy Switches Card (Only visible when NOT in preview) ─
                      if (!_isPreviewMode) ...[
                        _buildPrivacySettingsCard(user),
                        const Gap(20),
                      ],

                      // ── 4. Workout Cumulative Stats Grid ──────────────────────────
                      Text('Athletic Records 🎖️', style: AppTheme.headlineMedium),
                      const Gap(12),
                      _buildRecordsGrid(user),
                      const Gap(24),

                      // ── 5. Consistency Commits Grid (GitHub-style calendar) ──────
                      Text('Workout Consistency 📅', style: AppTheme.headlineMedium),
                      const Gap(12),
                      _buildConsistencyGrid(user),
                      const Gap(24),

                      // ── 6. Interactive Performance Progress Chart ─────────────────
                      Text('Weekly Running Progress 📈', style: AppTheme.headlineMedium),
                      const Gap(12),
                      _buildRunningBarChart(user),

                      // Bottom Padding
                      const Gap(100),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Profile loading failed: $e', style: const TextStyle(color: AppTheme.accentRed))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewToggle() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.04),
          child: InkWell(
            onTap: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isPreviewMode ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: _isPreviewMode ? AppTheme.accentGreen : AppTheme.textMuted,
                    size: 16,
                  ),
                  const Gap(6),
                  Text(
                    _isPreviewMode ? 'Public Mode' : 'Owner View',
                    style: AppTheme.caption.copyWith(
                      color: _isPreviewMode ? AppTheme.accentGreen : AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryStart, width: 2),
                  gradient: AppTheme.brandGradient,
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
              ),
              const Gap(18),

              // Username & Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${user.username}',
                      style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryEnd, size: 14),
                        const Gap(4),
                        Text(
                          '${user.district}, ${user.country}',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentOrange, size: 16),
                    const Gap(4),
                    Text(
                      '${user.streakCount}D',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.accentOrange, fontWeight: FontWeight.w900),
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

  Widget _buildStatureGrid(UserModel user) {
    // Determine STATURE metrics public lock values
    final showHeight = !_isPreviewMode || user.showHeightToPublic;
    final showWeight = !_isPreviewMode || user.showWeightToPublic;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatureCard(
          title: 'HEIGHT STATURE',
          value: showHeight ? '${user.height.round()} cm' : '🔒 Private',
          icon: Icons.straighten_rounded,
          color: showHeight ? AppTheme.primaryStart : AppTheme.textMuted,
          isLocked: !showHeight,
        ),
        _buildStatureCard(
          title: 'BODY WEIGHT',
          value: showWeight ? '${user.weight.round()} kg' : '🔒 Private',
          icon: Icons.scale_rounded,
          color: showWeight ? AppTheme.primaryMid : AppTheme.textMuted,
          isLocked: !showWeight,
        ),
        _buildStatureCard(
          title: 'AGE METRIC',
          value: '${user.age} yrs',
          icon: Icons.cake_rounded,
          color: AppTheme.primaryEnd,
        ),
        _buildStatureCard(
          title: 'BIOLOGICAL GENDER',
          value: user.gender,
          icon: Icons.wc_rounded,
          color: AppTheme.accentGreen,
        ),
      ],
    );
  }

  Widget _buildStatureCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLocked = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked ? AppTheme.accentRed.withOpacity(0.15) : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.5),
                  ),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : icon,
                    color: isLocked ? AppTheme.accentRed : color,
                    size: 18,
                  ),
                ],
              ),
              Text(
                value,
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isLocked ? AppTheme.accentRed.withOpacity(0.8) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySettingsCard(UserModel user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppTheme.accentGreen, size: 20),
                  const Gap(8),
                  Text(
                    'Profile Privacy Controls',
                    style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Gap(16),
              _buildPrivacyRow(
                label: 'Private Account Profile',
                description: 'Hides your profile completely from lists and search.',
                value: user.isPrivate,
                onChanged: (val) => _updatePrivacyField('isPrivate', val),
              ),
              Divider(color: Colors.white.withOpacity(0.06), height: 24),
              _buildPrivacyRow(
                label: 'Reveal Height to Public',
                description: 'Shows your height stature to users viewing your profile.',
                value: user.showHeightToPublic,
                onChanged: (val) => _updatePrivacyField('showHeightToPublic', val),
              ),
              Divider(color: Colors.white.withOpacity(0.06), height: 24),
              _buildPrivacyRow(
                label: 'Reveal Weight to Public',
                description: 'Shows your body weight scale to users viewing your profile.',
                value: user.showWeightToPublic,
                onChanged: (val) => _updatePrivacyField('showWeightToPublic', val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyRow({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Gap(4),
              Text(
                description,
                style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const Gap(12),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentGreen,
          activeTrackColor: AppTheme.accentGreen.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildRecordsGrid(UserModel user) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.45,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildRecordCard(
          title: 'Pushups',
          value: '${user.totalPushups} reps',
          icon: Icons.fitness_center_rounded,
          color: AppTheme.primaryStart,
        ),
        _buildRecordCard(
          title: 'Squats',
          value: '${user.totalSquats} reps',
          icon: Icons.accessibility_new_rounded,
          color: AppTheme.primaryMid,
        ),
        _buildRecordCard(
          title: 'Jumps',
          value: '${user.totalJumps} reps',
          icon: Icons.bolt_rounded,
          color: AppTheme.primaryEnd,
        ),
        _buildRecordCard(
          title: 'Total Running',
          value: '${user.totalRunningDistance.toStringAsFixed(1)} km',
          icon: Icons.directions_run_rounded,
          color: AppTheme.accentGreen,
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.5),
                  ),
                  Icon(icon, color: color, size: 18),
                ],
              ),
              Text(
                value,
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsistencyGrid(UserModel user) {
    // Generate simulated commit matrix (4 weeks x 7 days)
    // Vary colors to match consistency intensities (like GitHub contribution grid)
    final gridItems = [
      0, 2, 4, 0, 1, 3, 5,
      2, 0, 3, 0, 4, 2, 1,
      4, 1, 0, 5, 2, 0, 3,
      3, 4, 1, 0, 5, 2, 1
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              final score = gridItems[index];
              Color cellColor = Colors.white.withOpacity(0.05); // No activity

              if (score == 1) {
                cellColor = AppTheme.accentGreen.withOpacity(0.2);
              } else if (score == 2) {
                cellColor = AppTheme.accentGreen.withOpacity(0.4);
              } else if (score == 3) {
                cellColor = AppTheme.accentGreen.withOpacity(0.6);
              } else if (score == 4) {
                cellColor = AppTheme.accentGreen.withOpacity(0.8);
              } else if (score == 5) {
                cellColor = AppTheme.accentGreen;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.02)),
                  boxShadow: score == 5
                      ? [BoxShadow(color: AppTheme.accentGreen.withOpacity(0.25), blurRadius: 4)]
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRunningBarChart(UserModel user) {
    // Simulated weekly running distance: Mon to Sun (in km)
    final weeklyDistances = [3.2, 5.0, 0.0, 4.5, 6.8, 0.0, 8.5];
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WEEKLY TOTAL',
                    style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 0.5),
                  ),
                  Text(
                    '${user.totalRunningDistance.toStringAsFixed(1)} KM',
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.accentGreen, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const Gap(28),
              // Draw Custom Bar Chart using Containers & Row Layouts
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(weeklyDistances.length, (index) {
                    final double val = weeklyDistances[index];
                    final double ratio = val / 10.0; // Max capacity scaling (10km limit)
                    final double barHeight = ratio * 100.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            '${val.toStringAsFixed(1)}',
                            style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 8),
                          ),
                        const Gap(6),
                        Container(
                          width: 16,
                          height: max(barHeight, 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: val > 0
                                ? const LinearGradient(
                                    colors: [AppTheme.primaryStart, AppTheme.accentGreen],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                            color: val == 0 ? Colors.white.withOpacity(0.05) : null,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          weekDays[index],
                          style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
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
