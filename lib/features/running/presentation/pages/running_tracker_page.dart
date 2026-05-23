import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/domain/providers/auth_provider.dart';
import 'package:sweatera/features/profile/data/repositories/user_profile_provider.dart';
import 'package:sweatera/features/running/data/repositories/running_repository_provider.dart';
import 'package:sweatera/features/running/domain/models/running_session_model.dart';

enum TrackingState { idle, active, paused }

/// RunningTrackerPage — Premium futuristic real-time GPS run tracker.
class RunningTrackerPage extends ConsumerStatefulWidget {
  const RunningTrackerPage({super.key});

  @override
  ConsumerState<RunningTrackerPage> createState() => _RunningTrackerPageState();
}

class _RunningTrackerPageState extends ConsumerState<RunningTrackerPage> {
  // Tracking state
  TrackingState _state = TrackingState.idle;
  LocationPermission _permission = LocationPermission.denied;
  bool _isCheckingPermission = true;

  // Live session statistics
  double _distance = 0.0; // in km
  double _speed = 0.0;    // in km/h
  double _avgSpeed = 0.0; // in km/h
  int _calories = 0;      // in kcal
  Duration _duration = Duration.zero;

  // Route points
  final List<Map<String, double>> _routePoints = [];

  // Active location stream & timer
  StreamSubscription<Position>? _locationSubscription;
  Timer? _timer;
  Position? _lastPosition;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permission = LocationPermission.denied;
        _isCheckingPermission = false;
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() {
      _permission = permission;
      _isCheckingPermission = false;
    });
  }

  void _startTracking() async {
    if (_permission == LocationPermission.denied || _permission == LocationPermission.deniedForever) {
      _checkLocationPermission();
      return;
    }

    _startTime = DateTime.now();
    _lastPosition = null;
    _distance = 0.0;
    _speed = 0.0;
    _avgSpeed = 0.0;
    _calories = 0;
    _duration = Duration.zero;
    _routePoints.clear();

    setState(() {
      _state = TrackingState.active;
    });

    _startTimer();
    _subscribeToLocationUpdates();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == TrackingState.active) {
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
          _calculateAnalytics();
        });
      }
    });
  }

  void _subscribeToLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Update every 3 meters
    );

    _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_state != TrackingState.active) return;

        setState(() {
          _speed = position.speed * 3.6; // Convert m/s to km/h

          if (_lastPosition != null) {
            // Calculate distance between current and last point in meters
            final double gapDistance = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            // Accumulate distance in km
            _distance += gapDistance / 1000.0;
          }

          _lastPosition = position;
          _routePoints.add({
            'lat': position.latitude,
            'lng': position.longitude,
          });
        });
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );
  }

  void _calculateAnalytics() {
    if (_duration.inSeconds == 0) return;

    // Average Speed: Total distance / Total time (hours)
    final double hours = _duration.inSeconds / 3600.0;
    _avgSpeed = _distance / hours;

    // Fetch user weight from Firestore model profile, fallback to 70kg
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final double weight = (userProfile?.weight ?? 70).toDouble();

    // MET equation: Calories = MET * weight(kg) * time(hours)
    // Running MET value averages 9.8 for steady cardio speed
    const double runningMET = 9.8;
    _calories = (runningMET * weight * hours).round();
  }

  void _pauseTracking() {
    _locationSubscription?.pause();
    setState(() {
      _state = TrackingState.paused;
    });
  }

  void _resumeTracking() {
    _locationSubscription?.resume();
    setState(() {
      _state = TrackingState.active;
    });
  }

  Future<void> _stopAndSaveTracking() async {
    _locationSubscription?.cancel();
    _timer?.cancel();

    // Show visual loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        final repository = ref.read(runningRepositoryProvider);
        final runId = const Uuid().v4();

        final session = RunningSessionModel(
          id: runId,
          uid: user.uid,
          distance: double.parse(_distance.toStringAsFixed(2)),
          avgSpeed: double.parse(_avgSpeed.toStringAsFixed(1)),
          calories: _calories,
          route: _routePoints,
          startedAt: _startTime ?? DateTime.now().subtract(_duration),
          endedAt: DateTime.now(),
        );

        await repository.saveRunningSession(session);
        ref.invalidate(userProfileProvider); // Force refresh dashboard statistics
      }
    } catch (e) {
      debugPrint('Save run error: $e');
    }

    if (mounted) {
      Navigator.pop(context); // Pop loading dialog
      Navigator.pop(context); // Return to Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run tracked successfully! Syncing to your profile.')),
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String hours = twoDigits(d.inHours);
    final String minutes = twoDigits(d.inMinutes.remainder(60));
    final String seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatPace() {
    if (_speed <= 0.5) return "-'--\"";
    // Pace: Minutes per kilometer. e.g. 1000m / speed(m/s) -> seconds/km -> convert to min/sec
    final double speedMetersPerSecond = _speed / 3.6;
    final double secondsPerKm = 1000.0 / speedMetersPerSecond;
    final int minutes = (secondsPerKm / 60.0).floor();
    final int seconds = (secondsPerKm % 60.0).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Elegant lock overlay if permission is not granted
    if (_permission == LocationPermission.denied || _permission == LocationPermission.deniedForever) {
      return _buildPermissionLockScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cybernetic Background Glow ─────────────────────────────────────────
          _BackgroundGlow(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── Premium Glass Header ──────────────────────────────────────────
                  _buildHeader(),
                  const Gap(20),

                  // ── Visual Glowing Route Painter Card ─────────────────────────────
                  Expanded(
                    child: _buildVisualRouteCard(),
                  ),
                  const Gap(20),

                  // ── Numeric Analytics Cards Grid ──────────────────────────────────
                  _buildAnalyticsGrid(),
                  const Gap(24),

                  // ── Active Control Action Panel ───────────────────────────────────
                  _buildControlPanel(),
                  const Gap(16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionLockScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _BackgroundGlow(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentRed.withOpacity(0.12),
                          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Icon(Icons.location_disabled_rounded, color: AppTheme.accentRed, size: 36),
                        ),
                      ),
                      const Gap(24),
                      Text(
                        'GPS Tracker Locked',
                        style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Gap(12),
                      Text(
                        'SweatEra requests high-accuracy location tracking to record your speed, pace, distance, and visual running route in real-time.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                      ),
                      const Gap(28),
                      Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppTheme.brandGradient,
                        ),
                        child: ElevatedButton(
                          onPressed: _checkLocationPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Grant GPS Access',
                            style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Gap(12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Return to Dashboard',
                          style: AppTheme.labelLarge.copyWith(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  if (_state != TrackingState.idle) {
                    _showExitConfirmationDialog();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'GPS RUN TRACKER',
                  style: AppTheme.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (_state == TrackingState.active)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentGreen,
                    boxShadow: [
                      BoxShadow(color: AppTheme.accentGreen, blurRadius: 8),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('Abandon Current Run?'),
        content: const Text('Your current running metrics and visual route tracking will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Abandon', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualRouteCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom route painter displaying the path dynamically on a digital grid
              CustomPaint(
                painter: _RunRoutePainter(
                  routePoints: _routePoints,
                ),
              ),

              // Distance indicator overlay
              Positioned(
                top: 24,
                left: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL CARDIO DISTANCE',
                      style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 0.5),
                    ),
                    const Gap(4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _distance.toStringAsFixed(2),
                          style: AppTheme.displayMedium.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..shader = AppTheme.brandGradient.createShader(
                                const Rect.fromLTWH(0, 0, 150, 50),
                              ),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          'KM',
                          style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Digital grid coordinate details
              Positioned(
                bottom: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppTheme.accentGreen, size: 14),
                      const Gap(6),
                      Text(
                        _routePoints.isEmpty
                            ? 'GPS CALIBRATING...'
                            : 'LAT: ${_routePoints.last['lat']!.toStringAsFixed(4)} LNG: ${_routePoints.last['lng']!.toStringAsFixed(4)}',
                        style: AppTheme.caption.copyWith(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGlassAnalyticsCard(
          title: 'DURATION',
          value: _formatDuration(_duration),
          icon: Icons.timer_rounded,
          color: AppTheme.primaryStart,
        ),
        _buildGlassAnalyticsCard(
          title: 'ACTIVE PACE',
          value: _formatPace(),
          icon: Icons.speed_rounded,
          color: AppTheme.primaryMid,
        ),
        _buildGlassAnalyticsCard(
          title: 'CURRENT SPEED',
          value: '${_speed.toStringAsFixed(1)} km/h',
          icon: Icons.directions_run_rounded,
          color: AppTheme.primaryEnd,
        ),
        _buildGlassAnalyticsCard(
          title: 'ENERGY METRICS',
          value: '$_calories kcal',
          icon: Icons.local_fire_department_rounded,
          color: AppTheme.accentOrange,
        ),
      ],
    );
  }

  Widget _buildGlassAnalyticsCard({
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
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

  Widget _buildControlPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_state == TrackingState.idle) ...[
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppTheme.brandGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryStart.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          const Gap(8),
                          Text(
                            'Start Running',
                            style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (_state == TrackingState.active) ...[
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentOrange, Colors.orange],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _pauseTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                          const Gap(8),
                          Text(
                            'Pause Session',
                            style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (_state == TrackingState.paused) ...[
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentGreen, AppTheme.primaryMid],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _resumeTracking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                const Gap(6),
                                Text(
                                  'Resume',
                                  style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentRed, Colors.redAccent],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _stopAndSaveTracking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                                const Gap(6),
                                Text(
                                  'Stop & Save',
                                  style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom Trail Renderer Painter ──────────────────────────────────────────

class _RunRoutePainter extends CustomPainter {
  final List<Map<String, double>> routePoints;

  _RunRoutePainter({required this.routePoints});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    // 1. Draw digital cybernetic background grids
    const double gridSpace = 30.0;
    for (double x = 0; x < size.width; x += gridSpace) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpace) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (routePoints.isEmpty) {
      // Draw radar scan center beacon when starting up
      final center = Offset(size.width / 2, size.height / 2);
      final pulsePaint = Paint()
        ..color = AppTheme.accentGreen.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 40, pulsePaint);

      final pointPaint = Paint()
        ..color = AppTheme.accentGreen
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6, pointPaint);
      return;
    }

    // 2. Compute geographic coordinate bounds for dynamic grid scaling
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final pt in routePoints) {
      final lat = pt['lat']!;
      final lng = pt['lng']!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final double latSpan = maxLat - minLat;
    final double lngSpan = maxLng - minLng;

    // Linear scaling helper with 40px safe boundary padding
    const double padding = 45.0;
    Offset scalePoint(double lat, double lng) {
      if (latSpan == 0 || lngSpan == 0) {
        return Offset(size.width / 2, size.height / 2);
      }

      // Inverted latitude mapping since (0,0) is top-left in canvas space
      final double x = padding + (lng - minLng) / lngSpan * (size.width - padding * 2);
      final double y = size.height - (padding + (lat - minLat) / latSpan * (size.height - padding * 2));
      return Offset(x, y);
    }

    // 3. Render route path lines
    final pathPaint = Paint()
      ..color = AppTheme.accentGreen
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = AppTheme.accentGreen.withOpacity(0.3)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);

    final Path path = Path();
    for (int i = 0; i < routePoints.length; i++) {
      final pt = routePoints[i];
      final offset = scalePoint(pt['lat']!, pt['lng']!);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    if (routePoints.length > 1) {
      // Draw neon glow shadow and active line
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, pathPaint);
    }

    // 4. Render start (red dot) and live tracker (green pulsing dot)
    final startOffset = scalePoint(routePoints.first['lat']!, routePoints.first['lng']!);
    final endOffset = scalePoint(routePoints.last['lat']!, routePoints.last['lng']!);

    final startPaint = Paint()
      ..color = AppTheme.primaryStart
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startOffset, 6.0, startPaint);

    final pulsePaint = Paint()
      ..color = AppTheme.accentGreen.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, 14.0, pulsePaint);

    final endPaint = Paint()
      ..color = AppTheme.accentGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, 6.0, endPaint);
  }

  @override
  bool shouldRepaint(covariant _RunRoutePainter oldDelegate) => true;
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
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryMid.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGreen.withOpacity(0.1),
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
