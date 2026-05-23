import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel — Represents an athlete user profile document in Firestore.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String gender;
  final double weight; // in kg
  final double height; // in cm
  final int age;
  final String country;
  final String state;
  final String district;
  final DateTime createdAt;
  final bool isPrivate;           // Hide profile completely from search/ranks
  final bool showHeightToPublic;  // Hide height metric from public views
  final bool showWeightToPublic;  // Hide weight metric from public views
  final int streakCount;
  final int totalPushups;
  final int totalSquats;
  final int totalJumps;
  final double totalRunningDistance;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
    required this.createdAt,
    this.country = 'India',
    this.state = 'Karnataka',
    this.district = 'Bengaluru',
    this.isPrivate = false,
    this.showHeightToPublic = false, // High privacy default
    this.showWeightToPublic = false, // High privacy default
    this.streakCount = 0,
    this.totalPushups = 0,
    this.totalSquats = 0,
    this.totalJumps = 0,
    this.totalRunningDistance = 0.0,
  });

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? gender,
    double? weight,
    double? height,
    int? age,
    String? country,
    String? state,
    String? district,
    DateTime? createdAt,
    bool? isPrivate,
    bool? showHeightToPublic,
    bool? showWeightToPublic,
    int? streakCount,
    int? totalPushups,
    int? totalSquats,
    int? totalJumps,
    double? totalRunningDistance,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      showHeightToPublic: showHeightToPublic ?? this.showHeightToPublic,
      showWeightToPublic: showWeightToPublic ?? this.showWeightToPublic,
      streakCount: streakCount ?? this.streakCount,
      totalPushups: totalPushups ?? this.totalPushups,
      totalSquats: totalSquats ?? this.totalSquats,
      totalJumps: totalJumps ?? this.totalJumps,
      totalRunningDistance: totalRunningDistance ?? this.totalRunningDistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'gender': gender,
      'weight': weight,
      'height': height,
      'age': age,
      'country': country,
      'state': state,
      'district': district,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'showHeightToPublic': showHeightToPublic,
      'showWeightToPublic': showWeightToPublic,
      'streakCount': streakCount,
      'totalPushups': totalPushups,
      'totalSquats': totalSquats,
      'totalJumps': totalJumps,
      'totalRunningDistance': totalRunningDistance,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is int) return val.toDouble();
      return val as double;
    }

    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? 'Athlete',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      weight: toDouble(json['weight'], 70.0),
      height: toDouble(json['height'], 175.0),
      age: json['age'] as int? ?? 24,
      country: json['country'] as String? ?? 'India',
      state: json['state'] as String? ?? 'Karnataka',
      district: json['district'] as String? ?? 'Bengaluru',
      createdAt: (json['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isPrivate: json['isPrivate'] as bool? ?? false,
      showHeightToPublic: json['showHeightToPublic'] as bool? ?? false,
      showWeightToPublic: json['showWeightToPublic'] as bool? ?? false,
      streakCount: json['streakCount'] as int? ?? 0,
      totalPushups: json['totalPushups'] as int? ?? 0,
      totalSquats: json['totalSquats'] as int? ?? 0,
      totalJumps: json['totalJumps'] as int? ?? 0,
      totalRunningDistance: toDouble(json['totalRunningDistance'], 0.0),
    );
  }
}
