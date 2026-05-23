import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Provides the current Firebase Auth user stream.
/// Emits null when logged out, User when authenticated.
@riverpod
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

/// Provides the current auth user synchronously (can be null).
@riverpod
User? currentUser(Ref ref) {
  return FirebaseAuth.instance.currentUser;
}
