import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel — represents a user document in Firestore.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String gender;
  final double weight;
  final int age;
  final DateTime createdAt;
  final bool isPrivate;
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
    required this.age,
    required this.createdAt,
    this.isPrivate = false,
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
    int? age,
    DateTime? createdAt,
    bool? isPrivate,
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
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
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
      'age': age,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'streakCount': streakCount,
      'totalPushups': totalPushups,
      'totalSquats': totalSquats,
      'totalJumps': totalJumps,
      'totalRunningDistance': totalRunningDistance,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      gender: json['gender'] as String,
      weight: (json['weight'] as num).toDouble(),
      age: json['age'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isPrivate: json['isPrivate'] as bool? ?? false,
      streakCount: json['streakCount'] as int? ?? 0,
      totalPushups: json['totalPushups'] as int? ?? 0,
      totalSquats: json['totalSquats'] as int? ?? 0,
      totalJumps: json['totalJumps'] as int? ?? 0,
      totalRunningDistance: (json['totalRunningDistance'] as num? ?? 0.0).toDouble(),
    );
  }
}
