import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweatera/features/profile/data/models/user_model.dart';

/// UserRepository — handles Firestore database operations for user profiles.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Creates a new user profile in Firestore.
  Future<void> createUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toJson());
  }

  /// Fetches a user profile from Firestore by UID.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  /// Updates a user profile in Firestore.
  Future<void> updateUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toJson());
  }

  /// Checks if a username is already taken in the database.
  Future<bool> isUsernameUnique(String username) async {
    final query = await _usersCollection
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}
