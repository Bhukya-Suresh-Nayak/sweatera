import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Helper class to calculate angles between joint landmarks.
class AngleCalculator {
  AngleCalculator._();

  /// Calculates the 2D angle (in degrees) at the [middle] landmark between [first] and [last].
  static double calculateAngle({
    required PoseLandmark first,
    required PoseLandmark middle,
    required PoseLandmark last,
  }) {
    final double radians = atan2(last.y - middle.y, last.x - middle.x) -
        atan2(first.y - middle.y, first.x - middle.x);
    double degrees = radians * (180 / pi);
    degrees = degrees.abs(); // Angle is absolute
    if (degrees > 180) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }
}
