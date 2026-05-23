import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/auth/data/repositories/auth_repository.dart';

part 'auth_repository_provider.g.dart';

/// Provides the singleton AuthRepository instance.
@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository();
