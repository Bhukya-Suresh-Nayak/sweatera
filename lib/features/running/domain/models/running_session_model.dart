import 'package:cloud_firestore/cloud_firestore.dart';

/// RunningSessionModel — Represents a completed GPS tracking running session.
class RunningSessionModel {
  final String id;
  final String uid;
  final double distance; // in kilometers (km)
  final double avgSpeed; // in kilometers per hour (km/h)
  final int calories;    // in kilocalories (kcal)
  final List<Map<String, double>> route; // List of geographic coordinates [{'lat': 12.34, 'lng': 56.78}]
  final DateTime startedAt;
  final DateTime endedAt;

  const RunningSessionModel({
    required this.id,
    required this.uid,
    required this.distance,
    required this.avgSpeed,
    required this.calories,
    required this.route,
    required this.startedAt,
    required this.endedAt,
  });

  /// Calculates the duration of the run session.
  Duration get duration => endedAt.difference(startedAt);

  /// Converts the running session into a JSON/Map structure for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'distance': distance,
      'avgSpeed': avgSpeed,
      'calories': calories,
      'route': route,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
    };
  }

  /// Creates a running session from a Firestore document snapshot.
  factory RunningSessionModel.fromMap(Map<String, dynamic> map, String docId) {
    // Helper to safely parse double fields
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      return val as double;
    }

    // Helper to parse coordinate route lists
    List<Map<String, double>> parseRoute(dynamic rawRoute) {
      if (rawRoute == null || rawRoute is! List) return [];
      return rawRoute.map((item) {
        if (item is Map) {
          return {
            'lat': toDouble(item['lat']),
            'lng': toDouble(item['lng']),
          };
        }
        return <String, double>{};
      }).where((element) => element.isNotEmpty).toList();
    }

    return RunningSessionModel(
      id: docId,
      uid: map['uid'] as String? ?? '',
      distance: toDouble(map['distance']),
      avgSpeed: toDouble(map['avgSpeed']),
      calories: map['calories'] as int? ?? 0,
      route: parseRoute(map['route']),
      startedAt: (map['startedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      endedAt: (map['endedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
