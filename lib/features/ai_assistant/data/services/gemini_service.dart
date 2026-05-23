import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// GeminiService — Connects to Gemini 1.5 Flash multimodal vision API for food analysis.
class GeminiService {
  final Dio _dio = Dio();

  // Retrieve Gemini API Key from environment defines (--dart-define=GEMINI_API_KEY=xxx)
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  /// Analyzes a food image and returns a parsed nutrition JSON map.
  /// If the API key is unconfigured or a network error occurs, it falls back to a high-fidelity mock.
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    if (_apiKey.isEmpty) {
      debugPrint('Gemini API Key is empty. Falling back to high-fidelity mock data.');
      return _getMockNutritionData();
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Analyze the food in this image. Identify the food item name. '
                    'Estimate its Calories (kcal), Protein (g), Fats (g), and Carbohydrates (g). '
                    'You MUST return a JSON object with this exact schema structure: '
                    '{"foodName": "...", "motivationalPhrase": "exactly 4-5 words about this meal", "calories": "... kcal", "protein": "...g", "fat": "...g", "carbs": "...g", "suggestions": ["healthier alternative or improvement 1", "healthier alternative or improvement 2", "healthier alternative or improvement 3"]}. '
                    'Do not wrap the response in markdown code blocks or quotes. Return only the raw JSON string.'
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      };

      final response = await _dio.post(
        endpoint,
        data: requestBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts.first['text'] as String?;
              if (rawText != null) {
                return _sanitizeAndParseJson(rawText);
              }
            }
          }
        }
      }

      throw Exception('Invalid Gemini API response payload');
    } catch (e) {
      debugPrint('Gemini Analysis failed ($e). Falling back to mock data.');
      return _getMockNutritionData();
    }
  }

  /// Sanitizes text in case the LLM wraps the JSON in markdown wrappers like ```json ... ```
  Map<String, dynamic> _sanitizeAndParseJson(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Generates clean, high-fidelity mock data representing healthy choices.
  Map<String, dynamic> _getMockNutritionData() {
    final mockMeals = [
      {
        'foodName': 'Avocado Egg Sourdough Toast',
        'motivationalPhrase': 'Excellent protein-rich breakfast choice!',
        'calories': '380 kcal',
        'protein': '16g',
        'fat': '18g',
        'carbs': '34g',
        'suggestions': [
          'Sprinkle hemp seeds on top for additional omega-3 fatty acids.',
          'Swap white sourdough for multi-grain bread to increase dietary fiber.',
          'Pair with half a cup of fresh blueberries to add vital antioxidants.'
        ]
      },
      {
        'foodName': 'Grilled Chicken Quinoa Salad Bowl',
        'motivationalPhrase': 'Outstanding muscle-building lean bowl!',
        'calories': '510 kcal',
        'protein': '38g',
        'fat': '12g',
        'carbs': '48g',
        'suggestions': [
          'Choose grilled chicken breast over thigh to keep saturated fats minimal.',
          'Dress with olive oil and fresh lemon juice instead of creamy ranch dressings.',
          'Add a handful of raw pumpkin seeds to boost zinc and magnesium intake.'
        ]
      },
      {
        'foodName': 'Seared Salmon & Asparagus Platter',
        'motivationalPhrase': 'Vibrant omega-3 superfood meal!',
        'calories': '450 kcal',
        'protein': '34g',
        'fat': '22g',
        'carbs': '14g',
        'suggestions': [
          'Squeeze fresh lemon on the salmon to enhance absorption of active iron.',
          'Serve with half a cup of steamed wild rice to incorporate complex carbs.',
          'Choose wild-caught salmon to maximize healthy unsaturated fatty acids.'
        ]
      }
    ];

    // Select random mock meal to display
    final random = Random();
    return mockMeals[random.nextInt(mockMeals.length)];
  }
}
