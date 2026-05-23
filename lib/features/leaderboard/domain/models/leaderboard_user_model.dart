/// LeaderboardUserModel — Represents an athlete competitor on the rankings scoreboard.
class LeaderboardUserModel {
  final String uid;
  final String username;
  final int streakCount;
  final int totalPushups;
  final int totalSquats;
  final int totalJumps;
  final double totalRunningDistance;
  final String country;
  final String state;
  final String district;

  const LeaderboardUserModel({
    required this.uid,
    required this.username,
    required this.streakCount,
    required this.totalPushups,
    required this.totalSquats,
    required this.totalJumps,
    required this.totalRunningDistance,
    required this.country,
    required this.state,
    required this.district,
  });

  /// Gamified Fitness Scoring Equation:
  /// Points = (Pushups * 10) + (Squats * 12) + (Jumps * 8) + (Running Distance * 100) + (Streak * 50)
  int get totalScore {
    final int baseScore = (totalPushups * 10) +
        (totalSquats * 12) +
        (totalJumps * 8) +
        (totalRunningDistance * 100).round() +
        (streakCount * 50);
    return baseScore;
  }

  /// Parses an athlete competitor from a Firestore user document Map structure.
  factory LeaderboardUserModel.fromMap(Map<String, dynamic> map, String docId) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      return val as double;
    }

    return LeaderboardUserModel(
      uid: docId,
      username: map['username'] as String? ?? 'Athlete',
      streakCount: map['streakCount'] as int? ?? 0,
      totalPushups: map['totalPushups'] as int? ?? 0,
      totalSquats: map['totalSquats'] as int? ?? 0,
      totalJumps: map['totalJumps'] as int? ?? 0,
      totalRunningDistance: toDouble(map['totalRunningDistance']),
      country: map['country'] as String? ?? 'India',
      state: map['state'] as String? ?? 'Karnataka',
      district: map['district'] as String? ?? 'Bengaluru',
    );
  }
}
