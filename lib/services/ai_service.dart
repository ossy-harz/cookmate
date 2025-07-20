import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/recipe_model.dart';

class AIService extends ChangeNotifier {
  final String _apiKey = 'AIzaSyCgUiTrKvEqr8aUpH2ZlNsQs84dLlz5u-A'; // Replace with your actual API key
  final String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  final Uuid _uuid = const Uuid();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Generate a recipe using Gemini model
  Future<RecipeModel> generateRecipe({
    required List<String> ingredients,
    required List<String> dietaryPreferences,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create prompt for Gemini
      final prompt = _createRecipePrompt(ingredients, dietaryPreferences);
      
      // Make API request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parse the generated text into a recipe
        final recipe = _parseGeneratedRecipe(generatedText, ingredients, dietaryPreferences, userId);
        
        _isLoading = false;
        notifyListeners();
        return recipe;
      } else {
        throw Exception('Failed to generate recipe: ${response.body}');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      // Fallback to a mock recipe if API fails
      return _createMockRecipe(ingredients, dietaryPreferences, userId);
    }
  }
  
  // Create a prompt for the Gemini model
  String _createRecipePrompt(List<String> ingredients, List<String> dietaryPreferences) {
    final ingredientsText = ingredients.join(', ');
    final preferencesText = dietaryPreferences.isEmpty 
        ? 'no specific dietary preferences' 
        : dietaryPreferences.join(', ');
    
    return '''
    Create a detailed recipe using these ingredients: $ingredientsText.
    
    Dietary preferences: $preferencesText.
    
    Format the response as follows:
    
    TITLE: [Recipe title]
    DESCRIPTION: [Brief description]
    PREP TIME: [Time in minutes]
    COOK TIME: [Time in minutes]
    SERVINGS: [Number]
    INGREDIENTS:
    - [Ingredient 1]: [Quantity] [Unit]
    - [Ingredient 2]: [Quantity] [Unit]
    ...
    INSTRUCTIONS:
    1. [Step 1]
    2. [Step 2]
    ...
    NUTRITION:
    Calories: [Number]
    Protein: [Number]g
    Carbs: [Number]g
    Fat: [Number]g
    
    Be creative but realistic. The recipe should be practical and delicious.
    ''';
  }
  
  // Parse the generated text into a RecipeModel
  RecipeModel _parseGeneratedRecipe(
    String generatedText, 
    List<String> providedIngredients, 
    List<String> dietaryPreferences,
    String userId,
  ) {
    try {
      // Extract title
      final titleMatch = RegExp(r'TITLE:\s*(.+)').firstMatch(generatedText);
      final title = titleMatch?.group(1) ?? 'AI Generated Recipe';
      
      // Extract description
      final descMatch = RegExp(r'DESCRIPTION:\s*(.+?)(?=\n|PREP TIME)').firstMatch(generatedText);
      final description = descMatch?.group(1) ?? 'A delicious recipe created with AI.';
      
      // Extract prep time
      final prepMatch = RegExp(r'PREP TIME:\s*(\d+)').firstMatch(generatedText);
      final prepTime = int.tryParse(prepMatch?.group(1) ?? '') ?? 15;
      
      // Extract cook time
      final cookMatch = RegExp(r'COOK TIME:\s*(\d+)').firstMatch(generatedText);
      final cookTime = int.tryParse(cookMatch?.group(1) ?? '') ?? 30;
      
      // Extract servings
      final servingsMatch = RegExp(r'SERVINGS:\s*(\d+)').firstMatch(generatedText);
      final servings = int.tryParse(servingsMatch?.group(1) ?? '') ?? 4;
      
      // Extract ingredients
      final ingredientsSection = RegExp(r'INGREDIENTS:(.*?)(?=INSTRUCTIONS|NUTRITION)', dotAll: true).firstMatch(generatedText)?.group(1) ?? '';
      final ingredientLines = ingredientsSection.split('\n').where((line) => line.trim().isNotEmpty && line.contains(':'));
      
      final ingredients = ingredientLines.map((line) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final name = parts[0].replaceAll('-', '').trim();
          final quantityParts = parts[1].trim().split(' ');
          final quantity = quantityParts.isNotEmpty ? quantityParts[0] : '1';
          final unit = quantityParts.length > 1 ? quantityParts.sublist(1).join(' ') : '';
          
          return Ingredient(
            name: name,
            quantity: quantity,
            unit: unit,
          );
        }
        return Ingredient(name: line.trim(), quantity: '1', unit: '');
      }).toList();
      
      // If no ingredients were parsed, use the provided ingredients
      if (ingredients.isEmpty) {
        providedIngredients.forEach((ingredient) {
          ingredients.add(Ingredient(name: ingredient, quantity: '1', unit: 'cup'));
        });
      }
      
      // Extract instructions
      final instructionsSection = RegExp(r'INSTRUCTIONS:(.*?)(?=NUTRITION|$)', dotAll: true).firstMatch(generatedText)?.group(1) ?? '';
      final instructionLines = instructionsSection.split('\n').where((line) => line.trim().isNotEmpty);
      
      final instructions = instructionLines.map((line) {
        return line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
      }).where((instruction) => instruction.isNotEmpty).toList();
      
      // If no instructions were parsed, add default instructions
      if (instructions.isEmpty) {
        instructions.addAll([
          'Combine all ingredients in a bowl.',
          'Mix well and season to taste.',
          'Cook according to your preference.',
          'Serve and enjoy your meal!',
        ]);
      }
      
      // Extract nutrition info
      final caloriesMatch = RegExp(r'Calories:\s*(\d+)').firstMatch(generatedText);
      final proteinMatch = RegExp(r'Protein:\s*(\d+)').firstMatch(generatedText);
      final carbsMatch = RegExp(r'Carbs:\s*(\d+)').firstMatch(generatedText);
      final fatMatch = RegExp(r'Fat:\s*(\d+)').firstMatch(generatedText);
      
      final calories = int.tryParse(caloriesMatch?.group(1) ?? '') ?? 400;
      final protein = double.tryParse(proteinMatch?.group(1) ?? '') ?? 15;
      final carbs = double.tryParse(carbsMatch?.group(1) ?? '') ?? 40;
      final fat = double.tryParse(fatMatch?.group(1) ?? '') ?? 20;
      
      // Create the recipe model
      final recipeId = _uuid.v4();
      
      return RecipeModel(
        id: recipeId,
        title: title,
        description: description,
        imageUrl: 'https://source.unsplash.com/random/800x600/?food,${title.split(' ').first}',
        categories: ['AI Generated'],
        cuisineTypes: ['Fusion'],
        dietaryTypes: dietaryPreferences,
        prepTimeMinutes: prepTime,
        cookTimeMinutes: cookTime,
        servings: servings,
        ingredients: ingredients,
        instructions: instructions,
        nutritionInfo: {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
        authorId: userId,
        isAIGenerated: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing generated recipe: $e');
      return _createMockRecipe(providedIngredients, dietaryPreferences, userId);
    }
  }
  
  // Create a mock recipe as fallback
  RecipeModel _createMockRecipe(List<String> ingredients, List<String> dietaryPreferences, String userId) {
    final recipeId = _uuid.v4();
    final mainIngredient = ingredients.isNotEmpty ? ingredients.first : 'ingredients';
    
    return RecipeModel(
      id: recipeId,
      title: 'AI Generated ${mainIngredient.capitalize()} Recipe',
      description: 'A delicious recipe created by AI using your available ingredients.',
      imageUrl: 'https://source.unsplash.com/random/800x600/?food,$mainIngredient',
      categories: ['AI Generated'],
      cuisineTypes: ['Fusion'],
      dietaryTypes: dietaryPreferences,
      prepTimeMinutes: 20,
      cookTimeMinutes: 30,
      servings: 4,
      ingredients: ingredients.map((name) => Ingredient(
        name: name,
        quantity: '1',
        unit: 'cup',
      )).toList(),
      instructions: [
        'Combine all ingredients in a bowl.',
        'Mix well and season to taste.',
        'Cook according to your preference.',
        'Serve and enjoy your AI-created meal!',
      ],
      nutritionInfo: {
        'calories': 400,
        'protein': 15,
        'carbs': 40,
        'fat': 20,
      },
      authorId: userId,
      isAIGenerated: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

