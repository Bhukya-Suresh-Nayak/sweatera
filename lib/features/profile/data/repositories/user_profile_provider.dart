import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/auth/domain/providers/auth_provider.dart';
import 'package:sweatera/features/profile/data/models/user_model.dart';
import 'package:sweatera/features/profile/data/repositories/user_repository_provider.dart';

part 'user_profile_provider.g.dart';

/// Fetches the current logged-in user's profile from Firestore.
@riverpod
Future<UserModel?> userProfile(Ref ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getUserProfile(user.uid);
}
