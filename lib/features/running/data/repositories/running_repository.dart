import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweatera/features/running/domain/models/running_session_model.dart';

/// RunningRepository — Manages database records for active/completed running sessions.
class RunningRepository {
  RunningRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _runningCollection =>
      _firestore.collection('running_sessions');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Saves a newly completed running session and updates the cumulative running statistics for the athlete.
  Future<void> saveRunningSession(RunningSessionModel session) async {
    // 1. Save session record under running_sessions collection
    await _runningCollection.doc(session.id).set(session.toMap());

    // 2. Increment user cumulative statistics in Firestore (total running distance and cumulative streak)
    final userRef = _usersCollection.doc(session.uid);
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final double currentDistance = (data['totalRunningDistance'] ?? 0.0) as double;
        final int currentStreak = (data['streakCount'] ?? 0) as int;

        transaction.update(userRef, {
          'totalRunningDistance': currentDistance + session.distance,
          'streakCount': currentStreak == 0 ? 1 : currentStreak,
        });
      }
    });
  }

  /// Fetches all running sessions recorded by a specific user.
  Future<List<RunningSessionModel>> getUserRunningSessions(String uid) async {
    final query = await _runningCollection
        .where('uid', isEqualTo: uid)
        .orderBy('startedAt', descending: true)
        .get();

    return query.docs.map((doc) {
      return RunningSessionModel.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
