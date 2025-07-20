import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntry> meals;
  final Map<String, dynamic>? nutritionSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlanModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
    this.nutritionSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'],
      userId: json['userId'],
      date: (json['date'] as Timestamp).toDate(),
      meals: (json['meals'] as List).map((m) => MealEntry.fromJson(m)).toList(),
      nutritionSummary: json['nutritionSummary'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'meals': meals.map((m) => m.toJson()).toList(),
      'nutritionSummary': nutritionSummary,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MealPlanModel copyWith({
    List<MealEntry>? meals,
    Map<String, dynamic>? nutritionSummary,
  }) {
    return MealPlanModel(
      id: this.id,
      userId: this.userId,
      date: this.date,
      meals: meals ?? this.meals,
      nutritionSummary: nutritionSummary ?? this.nutritionSummary,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MealEntry {
  final String id;
  final String mealType; // breakfast, lunch, dinner, snack
  final String recipeId;
  final String recipeName;
  final String? recipeImageUrl;
  final int servings;
  final Map<String, dynamic>? nutritionInfo;

  MealEntry({
    required this.id,
    required this.mealType,
    required this.recipeId,
    required this.recipeName,
    this.recipeImageUrl,
    required this.servings,
    this.nutritionInfo,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'],
      mealType: json['mealType'],
      recipeId: json['recipeId'],
      recipeName: json['recipeName'],
      recipeImageUrl: json['recipeImageUrl'],
      servings: json['servings'],
      nutritionInfo: json['nutritionInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeImageUrl': recipeImageUrl,
      'servings': servings,
      'nutritionInfo': nutritionInfo,
    };
  }
}

