import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:sweatera/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:sweatera/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:sweatera/features/profile/presentation/pages/profile_page.dart';

/// AppShell Navigation Provider to track the active bottom nav index.
final currentNavIndexProvider = StateProvider<int>((ref) => 0);

/// AppShell — The main navigational wrapper for the post-login app experience.
/// Renders an Instagram-style glassmorphism bottom navigation bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);

    final screens = <Widget>[
      const DashboardPage(),
      const LeaderboardPage(),
      const AiAssistantPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Keep all pages in an IndexedStack to preserve their state (e.g. scroll state)
          IndexedStack(
            index: currentIndex,
            children: screens,
          ),

          // Translucent Glassmorphic Bottom Navigation Bar pinned to the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: _GlassBottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => ref.read(currentNavIndexProvider.notifier).state = index,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomNavigationBar extends StatelessWidget {
  const _GlassBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.04),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    icon: Icons.emoji_events_outlined,
                    activeIcon: Icons.emoji_events_rounded,
                    label: 'Rankings',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavBarItem(
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome_rounded,
                    label: 'Assistant',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? ShaderMask(
                    shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
                    child: Icon(
                      activeIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  )
                : Icon(
                    icon,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
            const Gap(4),
            Text(
              label,
              style: isSelected
                  ? AppTheme.labelMedium.copyWith(
                      color: AppTheme.primaryStart,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    )
                  : AppTheme.labelMedium.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
