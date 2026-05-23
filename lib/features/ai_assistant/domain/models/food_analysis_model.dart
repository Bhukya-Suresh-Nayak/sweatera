import 'package:cloud_firestore/cloud_firestore.dart';

/// FoodAnalysisModel — Represents a nutrition scan and calorie analysis.
class FoodAnalysisModel {
  final String id;
  final String uid;
  final String foodName;
  final String motivationalPhrase;
  final String calories;
  final String protein;
  final String fat;
  final String carbs;
  final List<String> suggestions;
  final DateTime timestamp;

  const FoodAnalysisModel({
    required this.id,
    required this.uid,
    required this.foodName,
    required this.motivationalPhrase,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.suggestions,
    required this.timestamp,
  });

  /// Converts the food analysis model into a JSON Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'foodName': foodName,
      'motivationalPhrase': motivationalPhrase,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'suggestions': suggestions,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Creates a food analysis model from a Firestore snapshot.
  factory FoodAnalysisModel.fromMap(Map<String, dynamic> map, String docId) {
    return FoodAnalysisModel(
      id: docId,
      uid: map['uid'] as String? ?? '',
      foodName: map['foodName'] as String? ?? 'Unknown Meal',
      motivationalPhrase: map['motivationalPhrase'] as String? ?? 'Eat healthy, live active!',
      calories: map['calories'] as String? ?? '0 kcal',
      protein: map['protein'] as String? ?? '0g',
      fat: map['fat'] as String? ?? '0g',
      carbs: map['carbs'] as String? ?? '0g',
      suggestions: List<String>.from(map['suggestions'] ?? []),
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
