import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/profile/data/repositories/user_profile_provider.dart';
import 'package:sweatera/features/leaderboard/domain/models/leaderboard_user_model.dart';

part 'leaderboard_provider.g.dart';

/// Segmented location rankings provider: filters and orders competitors dynamically.
@riverpod
Stream<List<LeaderboardUserModel>> leaderboard(Ref ref, String level) {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;

  // Active geographic filters based on user locations (with fallback defaults)
  final String activeCountry = userProfile?.country ?? 'India';
  final String activeState = userProfile?.state ?? 'Karnataka';
  final String activeDistrict = userProfile?.district ?? 'Bengaluru';

  final firestore = FirebaseFirestore.instance;
  Query<Map<String, dynamic>> query = firestore.collection('users');

  // Apply location segments queries
  if (level == 'national') {
    query = query.where('country', isEqualTo: activeCountry);
  } else if (level == 'state') {
    query = query.where('state', isEqualTo: activeState);
  } else if (level == 'district') {
    query = query.where('district', isEqualTo: activeDistrict);
  }

  return query.snapshots().map((snapshot) {
    final List<LeaderboardUserModel> athletes = [];

    for (final doc in snapshot.docs) {
      if (doc.data().isNotEmpty) {
        athletes.add(LeaderboardUserModel.fromMap(doc.data(), doc.id));
      }
    }

    // 1. Sort athletes dynamically in-memory by computed Total Score descending
    athletes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // 2. Inject highly competitive mock competitors to populate rankings cleanly
    _injectMockCompetitors(athletes, level, activeCountry, activeState, activeDistrict);

    // 3. Re-sort final list to ensure absolute ranking correctness
    athletes.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return athletes;
  });
}

/// Dynamic mock competitor injector to maintain a highly active visual experience.
void _injectMockCompetitors(
  List<LeaderboardUserModel> athletes,
  String level,
  String country,
  String state,
  String district,
) {
  // Define standard mockup athletic profiles
  final mockData = [
    {
      'username': 'Aria_Fit_AI',
      'streakCount': 12,
      'totalPushups': 240,
      'totalSquats': 310,
      'totalJumps': 180,
      'totalRunningDistance': 35.5,
    },
    {
      'username': 'Iron_Maximus',
      'streakCount': 8,
      'totalPushups': 190,
      'totalSquats': 250,
      'totalJumps': 110,
      'totalRunningDistance': 22.0,
    },
    {
      'username': 'Zen_Yoga_Flow',
      'streakCount': 15,
      'totalPushups': 120,
      'totalSquats': 180,
      'totalJumps': 90,
      'totalRunningDistance': 15.2,
    },
    {
      'username': 'Cardio_King',
      'streakCount': 6,
      'totalPushups': 95,
      'totalSquats': 140,
      'totalJumps': 220,
      'totalRunningDistance': 42.1,
    },
    {
      'username': 'Running_Nomad',
      'streakCount': 4,
      'totalPushups': 60,
      'totalSquats': 110,
      'totalJumps': 70,
      'totalRunningDistance': 54.0,
    }
  ];

  // Map and append based on size checks
  for (int i = 0; i < mockData.length; i++) {
    final item = mockData[i];
    final mockUsername = item['username'] as String;

    // Check if mock user is already somehow represented to avoid duplicates
    if (athletes.any((a) => a.username == mockUsername)) continue;

    athletes.add(
      LeaderboardUserModel(
        uid: 'mock_user_$i',
        username: mockUsername,
        streakCount: item['streakCount'] as int,
        totalPushups: item['totalPushups'] as int,
        totalSquats: item['totalSquats'] as int,
        totalJumps: item['totalJumps'] as int,
        totalRunningDistance: item['totalRunningDistance'] as double,
        country: country,
        state: state,
        district: district,
      ),
    );
  }
}
