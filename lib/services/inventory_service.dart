import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../models/recipe_model.dart';

class InventoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user inventory items
  Stream<List<InventoryItemModel>> getUserInventory(String userId) {
    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItemModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get inventory items by category
  Stream<List<InventoryItemModel>> getInventoryByCategory(String userId, String category) {
    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItemModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get expiring items
  Stream<List<InventoryItemModel>> getExpiringItems(String userId, {int daysThreshold = 7}) {
    final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));

    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItemModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Add inventory item
  Future<String> addInventoryItem(InventoryItemModel item) async {
    try {
      final docRef = _firestore.collection('inventory').doc();

      final newItem = InventoryItemModel(
        id: docRef.id,
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        expiryDate: item.expiryDate,
        purchaseDate: item.purchaseDate,
        notes: item.notes,
        userId: item.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newItem.toJson());

      notifyListeners();
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update inventory item
  Future<void> updateInventoryItem(InventoryItemModel item) async {
    try {
      final updatedItem = InventoryItemModel(
        id: item.id,
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        expiryDate: item.expiryDate,
        purchaseDate: item.purchaseDate,
        notes: item.notes,
        userId: item.userId,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('inventory').doc(item.id).update(updatedItem.toJson());

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      await _firestore.collection('inventory').doc(itemId).delete();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update item quantity
  Future<void> updateItemQuantity(String itemId, double newQuantity) async {
    try {
      final docRef = _firestore.collection('inventory').doc(itemId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final item = InventoryItemModel.fromJson(docSnapshot.data()!);

        final updatedItem = item.copyWith(
          quantity: newQuantity,
        );

        await docRef.update({
          'quantity': newQuantity,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Generate grocery list based on recipes and current inventory
  Future<List<Map<String, dynamic>>> generateGroceryList(
      String userId,
      List<Map<String, dynamic>> plannedRecipes,
      ) async {
    try {
      // Get current inventory
      final inventorySnapshot = await _firestore
          .collection('inventory')
          .where('userId', isEqualTo: userId)
          .get();

      final currentInventory = inventorySnapshot.docs
          .map((doc) => InventoryItemModel.fromJson(doc.data()))
          .toList();

      // Extract all ingredients needed from planned recipes
      final List<Map<String, dynamic>> neededIngredients = [];

      for (final recipeData in plannedRecipes) {
        final recipeId = recipeData['recipeId'];
        final servings = recipeData['servings'];

        final recipeSnapshot = await _firestore.collection('recipes').doc(recipeId).get();

        if (recipeSnapshot.exists) {
          final recipe = RecipeModel.fromJson(recipeSnapshot.data()!);
          final servingRatio = servings / recipe.servings;

          for (final ingredient in recipe.ingredients) {
            // Try to parse quantity as double
            double? quantity = 0;
            try {
              quantity = double.parse(ingredient.quantity) * servingRatio;
            } catch (e) {
              // If parsing fails, use 1 as default
              quantity = (1 * servingRatio) as double?;
            }

            // Check if we already have this ingredient in our list
            final existingIndex = neededIngredients.indexWhere(
                    (item) => item['name'] == ingredient.name && item['unit'] == ingredient.unit
            );

            if (existingIndex >= 0) {
              // Add to existing quantity
              neededIngredients[existingIndex]['quantity'] += quantity;
            } else {
              // Add new ingredient
              neededIngredients.add({
                'name': ingredient.name,
                'quantity': quantity,
                'unit': ingredient.unit,
                'category': _getCategoryForIngredient(ingredient.name),
              });
            }
          }
        }
      }

      // Compare with current inventory and create grocery list
      final List<Map<String, dynamic>> groceryList = [];

      for (final neededIngredient in neededIngredients) {
        final matchingInventoryItem = currentInventory.firstWhere(
              (item) => item.name.toLowerCase() == neededIngredient['name'].toLowerCase(),
          orElse: () => InventoryItemModel(
            id: '',
            name: '',
            category: '',
            quantity: 0,
            unit: '',
            purchaseDate: DateTime.now(),
            userId: userId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (matchingInventoryItem.id.isEmpty ||
            matchingInventoryItem.quantity < neededIngredient['quantity']) {
          // Calculate how much we need to buy
          final double quantityToBuy = matchingInventoryItem.id.isEmpty
              ? neededIngredient['quantity']
              : neededIngredient['quantity'] - matchingInventoryItem.quantity;

          groceryList.add({
            'name': neededIngredient['name'],
            'quantity': quantityToBuy,
            'unit': neededIngredient['unit'],
            'category': neededIngredient['category'],
            'inInventory': matchingInventoryItem.id.isNotEmpty,
            'inventoryQuantity': matchingInventoryItem.id.isNotEmpty ? matchingInventoryItem.quantity : 0,
          });
        }
      }

      // Sort by category
      groceryList.sort((a, b) => a['category'].compareTo(b['category']));

      return groceryList;
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to categorize ingredients
  String _getCategoryForIngredient(String ingredientName) {
    final lowerName = ingredientName.toLowerCase();

    if (lowerName.contains('milk') ||
        lowerName.contains('cheese') ||
        lowerName.contains('yogurt') ||
        lowerName.contains('butter')) {
      return 'Dairy';
    } else if (lowerName.contains('chicken') ||
        lowerName.contains('beef') ||
        lowerName.contains('pork') ||
        lowerName.contains('fish') ||
        lowerName.contains('meat')) {
      return 'Meat & Seafood';
    } else if (lowerName.contains('apple') ||
        lowerName.contains('banana') ||
        lowerName.contains('orange') ||
        lowerName.contains('berry') ||
        lowerName.contains('fruit')) {
      return 'Fruits';
    } else if (lowerName.contains('carrot') ||
        lowerName.contains('onion') ||
        lowerName.contains('potato') ||
        lowerName.contains('tomato') ||
        lowerName.contains('vegetable')) {
      return 'Vegetables';
    } else if (lowerName.contains('bread') ||
        lowerName.contains('pasta') ||
        lowerName.contains('rice') ||
        lowerName.contains('flour') ||
        lowerName.contains('cereal')) {
      return 'Grains & Bakery';
    } else if (lowerName.contains('oil') ||
        lowerName.contains('vinegar') ||
        lowerName.contains('sauce') ||
        lowerName.contains('spice') ||
        lowerName.contains('herb')) {
      return 'Condiments & Spices';
    } else {
      return 'Other';
    }
  }
}

