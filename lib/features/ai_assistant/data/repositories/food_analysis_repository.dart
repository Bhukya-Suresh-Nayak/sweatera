import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweatera/features/ai_assistant/domain/models/food_analysis_model.dart';

/// FoodAnalysisRepository — Handles Firestore operations for AI nutrition meal scans.
class FoodAnalysisRepository {
  FoodAnalysisRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('food_analysis');

  /// Saves a newly analyzed meal into Firestore history.
  Future<void> saveFoodAnalysis(FoodAnalysisModel analysis) async {
    await _collection.doc(analysis.id).set(analysis.toMap());
  }

  /// Fetches a user's past nutrition scan histories.
  Future<List<FoodAnalysisModel>> getUserFoodHistory(String uid) async {
    final query = await _collection
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();

    return query.docs.map((doc) {
      return FoodAnalysisModel.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
