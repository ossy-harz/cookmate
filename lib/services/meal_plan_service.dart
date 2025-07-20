import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';

class MealPlanService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  bool isLoading = false;
  List<MealPlanModel> _mealPlans = [];

  List<MealPlanModel> get mealPlans => _mealPlans;

  // Get meal plans for a specific date range
  Stream<List<MealPlanModel>> getMealPlans(String userId, DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('meal_plans')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MealPlanModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get meal plans for a specific date
  List<MealPlanModel> getMealPlansForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _mealPlans.where((plan) {
      final planDate = DateTime(plan.date.year, plan.date.month, plan.date.day);
      return planDate.isAtSameMomentAs(startOfDay);
    }).toList();
  }

  // Fetch meal plans for a date range
  Future<void> fetchMealPlans({required DateTime startDate, required DateTime endDate}) async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('meal_plans')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      _mealPlans = snapshot.docs
          .map((doc) => MealPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching meal plans: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Get meal plan for a specific date
  Future<MealPlanModel?> getMealPlanForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('meal_plans')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return MealPlanModel.fromJson(querySnapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      print('Error getting meal plan: $e');
      return null;
    }
  }

  // Add a meal plan
  Future<void> addMealPlan(MealPlanModel mealPlan) async {
    try {
      await _firestore.collection('meal_plans').doc(mealPlan.id).set(mealPlan.toJson());
      _mealPlans.add(mealPlan);
      notifyListeners();
    } catch (e) {
      print('Error adding meal plan: $e');
    }
  }

  // Create or update meal plan for a specific date
  Future<String> createOrUpdateMealPlan(String userId, DateTime date, List<MealEntry> meals) async {
    try {
      // Check if meal plan already exists for this date
      final existingPlan = await getMealPlanForDate(userId, date);

      if (existingPlan != null) {
        // Update existing meal plan
        final updatedPlan = existingPlan.copyWith(
          meals: meals,
        );

        await _firestore.collection('meal_plans').doc(existingPlan.id).update(updatedPlan.toJson());

        // Calculate and update nutrition summary
        await _updateNutritionSummary(existingPlan.id);

        notifyListeners();
        return existingPlan.id;
      } else {
        // Create new meal plan
        final docRef = _firestore.collection('meal_plans').doc();

        final newPlan = MealPlanModel(
          id: docRef.id,
          userId: userId,
          date: DateTime(date.year, date.month, date.day),
          meals: meals,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(newPlan.toJson());

        // Calculate and update nutrition summary
        await _updateNutritionSummary(docRef.id);

        notifyListeners();
        return docRef.id;
      }
    } catch (e) {
      print('Error creating/updating meal plan: $e');
      return '';
    }
  }

  // Add meal to a specific date
  Future<void> addMealToDate(String userId, DateTime date, String recipeId, String mealType, int servings) async {
    try {
      // Get recipe details
      final recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();

      if (!recipeDoc.exists) {
        throw Exception('Recipe not found');
      }

      final recipe = RecipeModel.fromJson(recipeDoc.data()!);

      // Create meal entry
      final mealEntry = MealEntry(
        id: _uuid.v4(),
        mealType: mealType,
        recipeId: recipeId,
        recipeName: recipe.title,
        recipeImageUrl: recipe.imageUrl,
        servings: servings,
        nutritionInfo: _calculateNutritionForServings(recipe.nutritionInfo, recipe.servings, servings),
      );

      // Get existing meal plan or create new one
      final existingPlan = await getMealPlanForDate(userId, date);

      if (existingPlan != null) {
        // Add to existing meals
        final updatedMeals = [...existingPlan.meals, mealEntry];

        await _firestore.collection('meal_plans').doc(existingPlan.id).update({
          'meals': updatedMeals.map((m) => m.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Update nutrition summary
        await _updateNutritionSummary(existingPlan.id);
      } else {
        // Create new meal plan
        final docRef = _firestore.collection('meal_plans').doc();

        final newPlan = MealPlanModel(
          id: docRef.id,
          userId: userId,
          date: DateTime(date.year, date.month, date.day),
          meals: [mealEntry],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(newPlan.toJson());

        // Update nutrition summary
        await _updateNutritionSummary(docRef.id);
      }

      notifyListeners();
    } catch (e) {
      print('Error adding meal to date: $e');
    }
  }

  // Generate weekly meal plan
  Future<List<MealPlanModel>> generateWeeklyMealPlan(List<RecipeModel> recipes) async {
    try {
      final List<MealPlanModel> weeklyPlan = [];
      final now = DateTime.now();

      // Generate meal plans for the next 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final mealPlan = MealPlanModel(
          id: _uuid.v4(),
          userId: 'userId', // This will be replaced with actual userId
          date: date,
          meals: _generateMealsForDay(recipes, date),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        weeklyPlan.add(mealPlan);
      }

      return weeklyPlan;
    } catch (e) {
      print('Error generating weekly meal plan: $e');
      return [];
    }
  }

  // Helper method to generate meals for a day
  List<MealEntry> _generateMealsForDay(List<RecipeModel> recipes, DateTime date) {
    if (recipes.isEmpty) return [];

    // Shuffle recipes to get random selection
    final shuffledRecipes = List<RecipeModel>.from(recipes)..shuffle();

    // Select recipes for breakfast, lunch, and dinner
    final breakfast = shuffledRecipes.isNotEmpty ? shuffledRecipes[0] : null;
    final lunch = shuffledRecipes.length > 1 ? shuffledRecipes[1] : null;
    final dinner = shuffledRecipes.length > 2 ? shuffledRecipes[2] : null;

    final meals = <MealEntry>[];

    if (breakfast != null) {
      meals.add(MealEntry(
        id: _uuid.v4(),
        mealType: 'breakfast',
        recipeId: breakfast.id,
        recipeName: breakfast.title,
        recipeImageUrl: breakfast.imageUrl,
        servings: 1,
        nutritionInfo: breakfast.nutritionInfo,
      ));
    }

    if (lunch != null) {
      meals.add(MealEntry(
        id: _uuid.v4(),
        mealType: 'lunch',
        recipeId: lunch.id,
        recipeName: lunch.title,
        recipeImageUrl: lunch.imageUrl,
        servings: 1,
        nutritionInfo: lunch.nutritionInfo,
      ));
    }

    if (dinner != null) {
      meals.add(MealEntry(
        id: _uuid.v4(),
        mealType: 'dinner',
        recipeId: dinner.id,
        recipeName: dinner.title,
        recipeImageUrl: dinner.imageUrl,
        servings: 1,
        nutritionInfo: dinner.nutritionInfo,
      ));
    }

    return meals;
  }

  // Remove meal from a specific date
  Future<void> removeMealFromDate(String userId, DateTime date, String mealId) async {
    try {
      final existingPlan = await getMealPlanForDate(userId, date);

      if (existingPlan != null) {
        // Remove the meal
        final updatedMeals = existingPlan.meals.where((meal) => meal.id != mealId).toList();

        await _firestore.collection('meal_plans').doc(existingPlan.id).update({
          'meals': updatedMeals.map((m) => m.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Update nutrition summary
        await _updateNutritionSummary(existingPlan.id);

        // If no meals left, delete the meal plan
        if (updatedMeals.isEmpty) {
          await _firestore.collection('meal_plans').doc(existingPlan.id).delete();
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error removing meal from date: $e');
    }
  }

  // Update meal servings
  Future<void> updateMealServings(String userId, DateTime date, String mealId, int newServings) async {
    try {
      final existingPlan = await getMealPlanForDate(userId, date);

      if (existingPlan != null) {
        // Find the meal to update
        final mealIndex = existingPlan.meals.indexWhere((meal) => meal.id == mealId);

        if (mealIndex >= 0) {
          final meal = existingPlan.meals[mealIndex];

          // Get recipe details to recalculate nutrition
          final recipeDoc = await _firestore.collection('recipes').doc(meal.recipeId).get();

          if (recipeDoc.exists) {
            final recipe = RecipeModel.fromJson(recipeDoc.data()!);

            // Create updated meal entry
            final updatedMeal = MealEntry(
              id: meal.id,
              mealType: meal.mealType,
              recipeId: meal.recipeId,
              recipeName: meal.recipeName,
              recipeImageUrl: meal.recipeImageUrl,
              servings: newServings,
              nutritionInfo: _calculateNutritionForServings(recipe.nutritionInfo, recipe.servings, newServings),
            );

            // Update the meal in the list
            final updatedMeals = [...existingPlan.meals];
            updatedMeals[mealIndex] = updatedMeal;

            await _firestore.collection('meal_plans').doc(existingPlan.id).update({
              'meals': updatedMeals.map((m) => m.toJson()).toList(),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });

            // Update nutrition summary
            await _updateNutritionSummary(existingPlan.id);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error updating meal servings: $e');
    }
  }

  // Calculate nutrition for a specific number of servings
  Map<String, dynamic>? _calculateNutritionForServings(
      Map<String, dynamic>? nutritionInfo,
      int recipeServings,
      int mealServings,
      ) {
    if (nutritionInfo == null) return null;

    final servingRatio = mealServings / recipeServings;
    final Map<String, dynamic> scaledNutrition = {};

    nutritionInfo.forEach((key, value) {
      if (value is num) {
        scaledNutrition[key] = (value * servingRatio).round();
      } else {
        scaledNutrition[key] = value;
      }
    });

    return scaledNutrition;
  }

  // Update nutrition summary for a meal plan
  Future<void> _updateNutritionSummary(String mealPlanId) async {
    try {
      final docRef = _firestore.collection('meal_plans').doc(mealPlanId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final mealPlan = MealPlanModel.fromJson(docSnapshot.data()!);

        // Calculate total nutrition
        final Map<String, dynamic> nutritionSummary = {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        };

        for (final meal in mealPlan.meals) {
          if (meal.nutritionInfo != null) {
            nutritionSummary['calories'] += meal.nutritionInfo!['calories'] ?? 0;
            nutritionSummary['protein'] += meal.nutritionInfo!['protein'] ?? 0;
            nutritionSummary['carbs'] += meal.nutritionInfo!['carbs'] ?? 0;
            nutritionSummary['fat'] += meal.nutritionInfo!['fat'] ?? 0;
          }
        }

        await docRef.update({
          'nutritionSummary': nutritionSummary,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error updating nutrition summary: $e');
    }
  }

// Generate meal plan suggestions based on user preferences and inventory
/*Future<List<Map<String, dynamic>>> generateMealPlanSuggestions(
    String userId,
    List<String> dietaryPreferences,
    int daysToGenerate,
  ) async {
    try {
      // Get recipes that match dietary preferences
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('dietaryTypes', arrayContainsAny: dietaryPreferences)
          .limit(50) // Limit to 50 recipes for performance
          .get();
      
      final availableRecipes = querySnapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
      
      if (availableRecipes.isEmpty) {
        return [];
      }
      
      // Shuffle recipes to get random suggestions
      availableRecipes.shuffle();
      
      // Generate meal plan suggestions
      final List<Map<String, dynamic>> suggestions = [];
      
      for (int day = 0; day < daysToGenerate; day++) {
        final breakfastIndex = (day * 3) % availableRecipes.length;
        final lunchIndex = (day * 3 + 1) % availableRecipes.length;
        final dinnerIndex = (day * 3 + 2) % availableRecipes.length;
        
        suggestions.add({
          'date': DateTime.now().add(Duration(days: day)),
          'meals': [
            {
              'mealType': 'breakfast',
              'recipe': availableRecipes[breakfastIndex],
              'servings': 1,
            },
            {
              'mealType': 'lunch',
              'recipe': availableRecipes[lunchIndex],
              'servings': 1,
            },
            {
              'mealType': 'dinner',
              'recipe': availableRecipes[dinnerIndex],
              'servings': 1,
            },
          ],
        });
      }
      
      return suggestions;
    } catch (e) {
      rethrow;
    }
  }*/
}

