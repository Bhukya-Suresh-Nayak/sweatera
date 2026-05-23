import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:sweatera/core/theme/app_theme.dart';
import 'package:sweatera/features/auth/domain/providers/auth_provider.dart';
import 'package:sweatera/features/ai_assistant/data/repositories/food_analysis_repository_provider.dart';
import 'package:sweatera/features/ai_assistant/data/services/gemini_service.dart';
import 'package:sweatera/features/ai_assistant/domain/models/food_analysis_model.dart';

/// AiAssistantPage — Premium Gemini-powered nutritionist meal scanner.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  File? _imageFile;
  bool _isAnalyzing = false;
  FoodAnalysisModel? _scanResult;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _isAnalyzing = true;
        _scanResult = null;
      });

      // Issue multimodal vision request to Gemini
      final jsonResult = await _geminiService.analyzeFoodImage(_imageFile!);

      // Save analyzed results to Firestore
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        final repository = ref.read(foodAnalysisRepositoryProvider);
        final docId = const Uuid().v4();

        final parsedResult = FoodAnalysisModel(
          id: docId,
          uid: user.uid,
          foodName: jsonResult['foodName'] as String? ?? 'Meal Scan',
          motivationalPhrase: jsonResult['motivationalPhrase'] as String? ?? 'Vibrant & healthy choice!',
          calories: jsonResult['calories'] as String? ?? '0 kcal',
          protein: jsonResult['protein'] as String? ?? '0g',
          fat: jsonResult['fat'] as String? ?? '0g',
          carbs: jsonResult['carbs'] as String? ?? '0g',
          suggestions: List<String>.from(jsonResult['suggestions'] ?? []),
          timestamp: DateTime.now(),
        );

        await repository.saveFoodAnalysis(parsedResult);
        setState(() {
          _scanResult = parsedResult;
        });
      }
    } catch (e) {
      debugPrint('Meal scan failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal analysis error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _imageFile = null;
      _scanResult = null;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cybernetic Background Glow ─────────────────────────────────────────
          _BackgroundGlow(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(20),
                  Text(
                    'AI Nutritionist 🥦',
                    style: AppTheme.displayMedium.copyWith(
                      foreground: Paint()
                        ..shader = AppTheme.brandGradient.createShader(
                          const Rect.fromLTWH(0, 0, 300, 60),
                        ),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    'Scan meal photos for instant protein, carbs, fats, and calorie tracking details.',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                  ),
                  const Gap(32),

                  // ── Switchable Flow: Scanner Upload VS Loading VS Results ──────────
                  if (_isAnalyzing) ...[
                    _buildLoadingCard(),
                  ] else if (_scanResult != null) ...[
                    _buildResultsPanel(),
                  ] else ...[
                    _buildUploadPanel(),
                  ],

                  // Extra bottom padding
                  const Gap(100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Glowing scan target scanner boundary
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryEnd.withOpacity(0.12),
                  border: Border.all(color: AppTheme.primaryEnd.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryEnd.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEnd, size: 48),
                ),
              ),
              const Gap(28),
              Text(
                'Identify Your Meal',
                style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const Gap(10),
              Text(
                'Snap a meal photo or upload from library. Our multi-modal Gemini model will instantly compute caloric and macronutrient values.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
              const Gap(32),

              // Upload Action triggers
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Take Photo',
                      icon: Icons.camera_alt_rounded,
                      gradient: AppTheme.brandGradient,
                      onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: _buildActionBtn(
                      label: 'Gallery',
                      icon: Icons.photo_library_rounded,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryMid, AppTheme.accentGreen],
                      ),
                      onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const Gap(8),
            Text(
              label,
              style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
          child: Column(
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEnd),
                ),
              ),
              const Gap(32),
              Text(
                'Gemini AI Analyzing...',
                style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const Gap(10),
              Text(
                'Running deep image identification, estimating protein density, active carbs, fats, and calculating raw calories.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsPanel() {
    final result = _scanResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal image display if picked
        if (_imageFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Image.file(_imageFile!, fit: BoxFit.cover),
            ),
          ),
          const Gap(24),
        ],

        // 🥦 Motivational phrase card (Exactly 4-5 words)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
          ),
          child: Text(
            result.motivationalPhrase.toUpperCase(),
            style: AppTheme.caption.copyWith(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Gap(10),

        // Food Name
        Text(
          result.foodName,
          style: AppTheme.displayMedium.copyWith(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const Gap(24),

        // 📊 UI Macro Table Card
        Text(
          'Nutrition Breakdown 📊',
          style: AppTheme.headlineMedium,
        ),
        const Gap(12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _buildTableCell(label: 'Calories', value: result.calories, color: AppTheme.primaryStart, icon: Icons.local_fire_department_rounded),
                  _buildTableCell(label: 'Protein', value: result.protein, color: AppTheme.primaryMid, icon: Icons.fitness_center_rounded),
                  _buildTableCell(label: 'Carbohydrates', value: result.carbs, color: AppTheme.primaryEnd, icon: Icons.grain_rounded),
                  _buildTableCell(label: 'Dietary Fats', value: result.fat, color: AppTheme.accentOrange, icon: Icons.opacity_rounded, isLast: true),
                ],
              ),
            ),
          ),
        ),
        const Gap(28),

        // 💡 AI Suggestions
        Text(
          'Healthier Alternatives & Tips 💡',
          style: AppTheme.headlineMedium,
        ),
        const Gap(12),
        Column(
          children: result.suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded, color: AppTheme.primaryEnd, size: 20),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(28),

        // Scan Another Meal Button
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: OutlinedButton(
            onPressed: _resetScan,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide.none,
            ),
            child: Text(
              'Scan Another Meal 🥦',
              style: AppTheme.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Gap(12),
              Text(label, style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: AppTheme.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background Glow Widget ───────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryEnd.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
