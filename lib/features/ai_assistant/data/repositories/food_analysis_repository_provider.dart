import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sweatera/features/ai_assistant/data/repositories/food_analysis_repository.dart';

part 'food_analysis_repository_provider.g.dart';

/// Provides the singleton FoodAnalysisRepository instance.
@riverpod
FoodAnalysisRepository foodAnalysisRepository(Ref ref) => FoodAnalysisRepository();
