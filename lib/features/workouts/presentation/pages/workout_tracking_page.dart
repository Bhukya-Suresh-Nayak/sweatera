import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/profile/data/repositories/user_profile_provider.dart';
import 'package:sweatera/features/profile/data/repositories/user_repository_provider.dart';
import 'package:sweatera/features/workouts/domain/angle_calculator.dart';

enum WorkoutType { pushups, squats, jumps }

/// WorkoutTrackingPage — Real-time athletic pose tracker.
/// Utilizes the camera stream and on-device MediaPipe ML Kit model for rep counting.
class WorkoutTrackingPage extends ConsumerStatefulWidget {
  const WorkoutTrackingPage({super.key});

  @override
  ConsumerState<WorkoutTrackingPage> createState() => _WorkoutTrackingPageState();
}

class _WorkoutTrackingPageState extends ConsumerState<WorkoutTrackingPage> {
  // Camera & ML Kit
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  late PoseDetector _poseDetector;

  // Selected Workout
  WorkoutType _selectedWorkout = WorkoutType.pushups;

  // Counter State
  int _pushupCount = 0;
  int _squatCount = 0;
  int _jumpCount = 0;
  String _stage = 'up'; // Stage of the exercise cycle

  // Skeletal Landmarks
  List<Pose> _detectedPoses = [];
  Size? _imageSize;

  // Jump tracking calibration
  double? _standingHipY;
  bool _isAirborne = false;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _requestPermissionAndInitCamera();
  }

  void _initializeDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  Future<void> _requestPermissionAndInitCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Select front camera by default for user workout tracking
        final frontCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
        _initCamera(frontCamera);
      }
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    _cameraController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      _isCameraInitialized = true;
      _imageSize = Size(
        _cameraController!.value.previewSize!.height,
        _cameraController!.value.previewSize!.width,
      );

      // Start streaming frames
      _cameraController!.startImageStream(_processCameraFrame);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessingFrame = false;
      return;
    }

    try {
      final poses = await _poseDetector.processImage(inputImage);
      _detectedPoses = poses;

      if (poses.isNotEmpty) {
        _runWorkoutCounter(poses.first);
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Pose processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ── Exercise Counting Engine ──────────────────────────────────────────────────

  void _runWorkoutCounter(Pose pose) {
    switch (_selectedWorkout) {
      case WorkoutType.pushups:
        _countPushups(pose);
        break;
      case WorkoutType.squats:
        _countSquats(pose);
        break;
      case WorkoutType.jumps:
        _countJumps(pose);
        break;
    }
  }

  void _countPushups(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return;

    // Use confidence threshold
    if (shoulder.likelihood < 0.5 || elbow.likelihood < 0.5 || wrist.likelihood < 0.5) return;

    final angle = AngleCalculator.calculateAngle(
      first: shoulder,
      middle: elbow,
      last: wrist,
    );

    if (angle < 90) {
      _stage = 'down';
    } else if (angle > 155 && _stage == 'down') {
      _pushupCount++;
      _stage = 'up';
    }
  }

  void _countSquats(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (hip == null || knee == null || ankle == null) return;
    if (hip.likelihood < 0.5 || knee.likelihood < 0.5 || ankle.likelihood < 0.5) return;

    final angle = AngleCalculator.calculateAngle(
      first: hip,
      middle: knee,
      last: ankle,
    );

    if (angle < 100) {
      _stage = 'down';
    } else if (angle > 155 && _stage == 'down') {
      _squatCount++;
      _stage = 'up';
    }
  }

  void _countJumps(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftHip == null || rightHip == null) return;
    if (leftHip.likelihood < 0.5 || rightHip.likelihood < 0.5) return;

    // Average hip Y-coordinate representing the center of mass
    final double currentHipY = (leftHip.y + rightHip.y) / 2.0;

    // Calibrate baseline standing position
    if (_standingHipY == null) {
      _standingHipY = currentHipY;
      return;
    }

    // In frame coordinates, (0,0) is top-left, so jumping up DECREASES Y-value
    final double displacement = _standingHipY! - currentHipY;

    if (displacement > 45 && !_isAirborne) {
      _isAirborne = true;
    } else if (displacement < 15 && _isAirborne) {
      _jumpCount++;
      _isAirborne = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotation.rotation90deg;
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.yuv420) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _completeSession() async {
    // Show saving status
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userProfile = ref.read(userProfileProvider).valueOrNull;
      if (userProfile != null) {
        final userRepo = ref.read(userRepositoryProvider);

        // Update statistics
        final updatedProfile = userProfile.copyWith(
          totalPushups: userProfile.totalPushups + _pushupCount,
          totalSquats: userProfile.totalSquats + _squatCount,
          totalJumps: userProfile.totalJumps + _jumpCount,
          streakCount: userProfile.streakCount == 0 ? 1 : userProfile.streakCount,
        );

        await userRepo.updateUserProfile(updatedProfile);
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      debugPrint('Save stats error: $e');
    }

    if (mounted) {
      Navigator.pop(context); // Pop loading dialog
      Navigator.pop(context); // Return to Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session completed! Stats saved in cloud database.')),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text('SweatEra uses on-device live computer vision to track your workouts. Please enable camera permissions in settings to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _selectedWorkout == WorkoutType.pushups
        ? _pushupCount
        : _selectedWorkout == WorkoutType.squats
            ? _squatCount
            : _jumpCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Feed & Pose Overlay ───────────────────────────────────────
          if (_isCameraInitialized && _cameraController != null) ...[
            CameraPreview(_cameraController!),
            if (_detectedPoses.isNotEmpty && _imageSize != null)
              CustomPaint(
                painter: _PosePainter(
                  poses: _detectedPoses,
                  imageSize: _imageSize!,
                  selectedWorkout: _selectedWorkout,
                ),
              ),
          ] else ...[
            const Center(child: CircularProgressIndicator()),
          ],

          // ── Top Glass Controller ──────────────────────────────────────────────
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: _TopWorkoutOverlay(
              selectedWorkout: _selectedWorkout,
              onWorkoutChanged: (w) {
                setState(() {
                  _selectedWorkout = w;
                  _stage = 'up';
                  _standingHipY = null;
                  _isAirborne = false;
                });
              },
            ),
          ),

          // ── Bottom Glass Stats ────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _BottomStatsOverlay(
              count: activeCount,
              stage: _stage,
              onFinish: _completeSession,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Skeletal Pose Painter ──────────────────────────────────────────────

class _PosePainter extends CustomPainter {
  _PosePainter({
    required this.poses,
    required this.imageSize,
    required this.selectedWorkout,
  });

  final List<Pose> poses;
  final Size imageSize;
  final WorkoutType selectedWorkout;

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final paintLine = Paint()
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintJoint = Paint()
      ..style = PaintingStyle.fill;

    // Define colors depending on selected exercise
    Color jointColor = AppTheme.primaryStart;
    Color lineColor = AppTheme.primaryEnd.withOpacity(0.6);

    if (selectedWorkout == WorkoutType.squats) {
      jointColor = AppTheme.primaryMid;
      lineColor = AppTheme.accentGreen.withOpacity(0.6);
    } else if (selectedWorkout == WorkoutType.jumps) {
      jointColor = AppTheme.primaryEnd;
      lineColor = AppTheme.primaryStart.withOpacity(0.6);
    }

    paintLine.color = lineColor;
    paintJoint.color = jointColor;

    for (final pose in poses) {
      // Connect key points for visual skeleton feedback
      _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, paintLine, scaleX, scaleY);

      // Connect right side joints
      _drawConnection(canvas, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, paintLine, scaleX, scaleY);

      // Connect shoulders and hips
      _drawConnection(canvas, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paintLine, scaleX, scaleY);
      _drawConnection(canvas, pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paintLine, scaleX, scaleY);

      // Draw Joint points
      pose.landmarks.forEach((type, landmark) {
        // Only draw main joints for cleaner skeleton
        if (type == PoseLandmarkType.leftShoulder ||
            type == PoseLandmarkType.leftElbow ||
            type == PoseLandmarkType.leftWrist ||
            type == PoseLandmarkType.leftHip ||
            type == PoseLandmarkType.leftKnee ||
            type == PoseLandmarkType.leftAnkle ||
            type == PoseLandmarkType.rightShoulder ||
            type == PoseLandmarkType.rightElbow ||
            type == PoseLandmarkType.rightWrist ||
            type == PoseLandmarkType.rightHip ||
            type == PoseLandmarkType.rightKnee ||
            type == PoseLandmarkType.rightAnkle) {
          final double x = landmark.x * scaleX;
          final double y = landmark.y * scaleY;
          canvas.drawCircle(Offset(x, y), 7.0, paintJoint);
        }
      });
    }
  }

  void _drawConnection(
    Canvas canvas,
    Pose pose,
    PoseLandmarkType type1,
    PoseLandmarkType type2,
    Paint paint,
    double scaleX,
    double scaleY,
  ) {
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];

    if (landmark1 != null && landmark2 != null) {
      if (landmark1.likelihood > 0.5 && landmark2.likelihood > 0.5) {
        canvas.drawLine(
          Offset(landmark1.x * scaleX, landmark1.y * scaleY),
          Offset(landmark2.x * scaleX, landmark2.y * scaleY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) => true;
}

// ── Top Bar Exercise Selector Overlay ────────────────────────────────────────

class _TopWorkoutOverlay extends StatelessWidget {
  const _TopWorkoutOverlay({
    required this.selectedWorkout,
    required this.onWorkoutChanged,
  });

  final WorkoutType selectedWorkout;
  final ValueChanged<WorkoutType> onWorkoutChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              const Gap(8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SelectorChip(
                      label: 'Pushups',
                      isSelected: selectedWorkout == WorkoutType.pushups,
                      onTap: () => onWorkoutChanged(WorkoutType.pushups),
                    ),
                    _SelectorChip(
                      label: 'Squats',
                      isSelected: selectedWorkout == WorkoutType.squats,
                      onTap: () => onWorkoutChanged(WorkoutType.squats),
                    ),
                    _SelectorChip(
                      label: 'Jumps',
                      isSelected: selectedWorkout == WorkoutType.jumps,
                      onTap: () => onWorkoutChanged(WorkoutType.jumps),
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

class _SelectorChip extends StatelessWidget {
  const _SelectorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppTheme.brandGradient : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Bottom Stats Overlay Component ────────────────────────────────────────────

class _BottomStatsOverlay extends StatelessWidget {
  const _BottomStatsOverlay({
    required this.count,
    required this.stage,
    required this.onFinish,
  });

  final int count;
  final String stage;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'COMPLETED REPS',
                      style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    const Gap(6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$count',
                          style: AppTheme.displayMedium.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = AppTheme.brandGradient.createShader(
                                const Rect.fromLTWH(0, 0, 100, 50),
                              ),
                          ),
                        ),
                        const Gap(10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stage.toUpperCase(),
                            style: AppTheme.labelLarge.copyWith(
                              color: stage == 'down' ? AppTheme.primaryStart : AppTheme.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppTheme.accentRed,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stop_rounded, color: Colors.white),
                    const Gap(8),
                    Text(
                      'Finish',
                      style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
