import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/profile/data/repositories/user_repository.dart';

part 'user_repository_provider.g.dart';

/// Provides the singleton UserRepository instance.
@riverpod
UserRepository userRepository(Ref ref) => UserRepository();
