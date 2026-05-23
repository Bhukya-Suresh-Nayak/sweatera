import 'package:flutter/material.dart';
import 'package:sweatera/core/theme/app_theme.dart';

/// SweatEra animated logo widget.
/// Renders the "S" monogram with brand gradient and a glowing shadow.
class SweateraLogo extends StatelessWidget {
  const SweateraLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryStart.withOpacity(0.45),
            blurRadius: size * 0.5,
            spreadRadius: -4,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: AppTheme.primaryEnd.withOpacity(0.2),
            blurRadius: size * 0.7,
            spreadRadius: -8,
            offset: Offset(0, size * 0.2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.52,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
