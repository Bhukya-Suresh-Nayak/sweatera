import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/running/data/repositories/running_repository.dart';

part 'running_repository_provider.g.dart';

/// Provides the singleton RunningRepository instance.
@riverpod
RunningRepository runningRepository(Ref ref) => RunningRepository();
