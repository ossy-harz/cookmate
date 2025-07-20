import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe_model.dart';

class RecipeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<RecipeModel> _recipes = [];
  bool _isLoading = false;

  List<RecipeModel> get recipes => _recipes;
  bool get isLoading => _isLoading;

  // Fetch user recipes
  Future<void> fetchUserRecipes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .get();
      
      _recipes = snapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching recipes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all recipes
  Stream<List<RecipeModel>> getRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RecipeModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get user recipes
  Stream<List<RecipeModel>> getUserRecipes(String userId) {
    return _firestore
        .collection('recipes')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RecipeModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get recipe by ID
  Future<RecipeModel?> getRecipeById(String recipeId) async {
    try {
      final docSnapshot = await _firestore.collection('recipes').doc(recipeId).get();
      
      if (docSnapshot.exists) {
        return RecipeModel.fromJson(docSnapshot.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error getting recipe: $e');
      return null;
    }
  }

  // Add a new recipe
  Future<String> addRecipe(RecipeModel recipe, File? imageFile) async {
    try {
      // Create a new document reference
      final docRef = _firestore.collection('recipes').doc();
      
      // Upload image if provided
      String imageUrl = recipe.imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadRecipeImage(docRef.id, imageFile);
      }
      
      // Create recipe with generated ID and image URL
      final newRecipe = RecipeModel(
        id: docRef.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: imageUrl,
        categories: recipe.categories,
        cuisineTypes: recipe.cuisineTypes,
        dietaryTypes: recipe.dietaryTypes,
        prepTimeMinutes: recipe.prepTimeMinutes,
        cookTimeMinutes: recipe.cookTimeMinutes,
        servings: recipe.servings,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        nutritionInfo: recipe.nutritionInfo,
        videoUrl: recipe.videoUrl,
        authorId: recipe.authorId,
        rating: recipe.rating,
        reviewCount: recipe.reviewCount,
        isAIGenerated: recipe.isAIGenerated,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      await docRef.set(newRecipe.toJson());
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      print('Error adding recipe: $e');
      return '';
    }
  }

  // Update a recipe
  Future<void> updateRecipe(RecipeModel recipe, File? imageFile) async {
    try {
      // Upload new image if provided
      String imageUrl = recipe.imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadRecipeImage(recipe.id, imageFile);
      }
      
      // Update recipe with new image URL if needed
      final updatedRecipe = RecipeModel(
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: imageFile != null ? imageUrl : recipe.imageUrl,
        categories: recipe.categories,
        cuisineTypes: recipe.cuisineTypes,
        dietaryTypes: recipe.dietaryTypes,
        prepTimeMinutes: recipe.prepTimeMinutes,
        cookTimeMinutes: recipe.cookTimeMinutes,
        servings: recipe.servings,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        nutritionInfo: recipe.nutritionInfo,
        videoUrl: recipe.videoUrl,
        authorId: recipe.authorId,
        rating: recipe.rating,
        reviewCount: recipe.reviewCount,
        isAIGenerated: recipe.isAIGenerated,
        createdAt: recipe.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _firestore.collection('recipes').doc(recipe.id).update(updatedRecipe.toJson());
      
      notifyListeners();
    } catch (e) {
      print('Error updating recipe: $e');
    }
  }

  // Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      // Delete recipe document
      await _firestore.collection('recipes').doc(recipeId).delete();
      
      // Delete associated image
      try {
        await _storage.ref('recipes/$recipeId').delete();
      } catch (e) {
        // Ignore if image doesn't exist
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting recipe: $e');
    }
  }

  // Upload recipe image
  Future<String> _uploadRecipeImage(String recipeId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('recipes/$recipeId');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  // Search recipes
  Future<List<RecipeModel>> searchRecipes(String query) async {
    try {
      // Search by title
      final titleSnapshot = await _firestore
          .collection('recipes')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      // Search by ingredients (this is a simple implementation)
      final ingredientSnapshot = await _firestore
          .collection('recipes')
          .get();
      
      final titleResults = titleSnapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
      
      // Filter ingredient results manually
      final ingredientResults = ingredientSnapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .where((recipe) => recipe.ingredients.any((ingredient) => 
              ingredient.name.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      // Combine results and remove duplicates
      final combinedResults = {...titleResults, ...ingredientResults}.toList();
      
      return combinedResults;
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  // Generate AI recipe (placeholder - would connect to a Cloud Function)
  Future<RecipeModel> generateAIRecipe(List<String> ingredients, Map<String, dynamic> preferences) async {
    try {
      // This would call a Cloud Function that uses an AI service
      // For now, we'll return a mock recipe
      
      final docRef = _firestore.collection('recipes').doc();
      
      final aiRecipe = RecipeModel(
        id: docRef.id,
        title: 'AI Generated Recipe with ${ingredients.first}',
        description: 'A delicious recipe created by AI using your available ingredients.',
        imageUrl: 'https://via.placeholder.com/400',
        categories: ['AI Generated'],
        cuisineTypes: ['Fusion'],
        dietaryTypes: preferences['dietaryTypes'] ?? [],
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
          'Cook according to your preference.',
          'Enjoy your AI-created meal!',
        ],
        nutritionInfo: {
          'calories': 400,
          'protein': 15,
          'carbs': 40,
          'fat': 20,
        },
        authorId: preferences['userId'],
        isAIGenerated: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      await docRef.set(aiRecipe.toJson());
      
      notifyListeners();
      return aiRecipe;
    } catch (e) {
      print('Error generating AI recipe: $e');
      throw Exception('Failed to generate recipe');
    }
  }

  // Toggle recipe favorite status
  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'isFavorite': isFavorite,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Update local cache if available
      final recipeIndex = _recipes.indexWhere((recipe) => recipe.id == recipeId);
      if (recipeIndex >= 0) {
        final updatedRecipe = _recipes[recipeIndex].copyWith(isFavorite: isFavorite);
        _recipes[recipeIndex] = updatedRecipe;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }
}

