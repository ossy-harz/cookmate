import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final List<String> cuisineTypes;
  final List<String> dietaryTypes;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final Map<String, dynamic> nutritionInfo;
  final String? videoUrl;
  final String? authorId;
  final double? rating;
  final int? reviewCount;
  final bool isAIGenerated;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.cuisineTypes,
    required this.dietaryTypes,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.nutritionInfo,
    this.videoUrl,
    this.authorId,
    this.rating,
    this.reviewCount,
    this.isAIGenerated = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      categories: List<String>.from(json['categories']),
      cuisineTypes: List<String>.from(json['cuisineTypes']),
      dietaryTypes: List<String>.from(json['dietaryTypes']),
      prepTimeMinutes: json['prepTimeMinutes'],
      cookTimeMinutes: json['cookTimeMinutes'],
      servings: json['servings'],
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      instructions: List<String>.from(json['instructions']),
      nutritionInfo: json['nutritionInfo'],
      videoUrl: json['videoUrl'],
      authorId: json['authorId'],
      rating: json['rating'],
      reviewCount: json['reviewCount'],
      isAIGenerated: json['isAIGenerated'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'categories': categories,
      'cuisineTypes': cuisineTypes,
      'dietaryTypes': dietaryTypes,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'nutritionInfo': nutritionInfo,
      'videoUrl': videoUrl,
      'authorId': authorId,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAIGenerated': isAIGenerated,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? categories,
    List<String>? cuisineTypes,
    List<String>? dietaryTypes,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    Map<String, dynamic>? nutritionInfo,
    String? videoUrl,
    String? authorId,
    double? rating,
    int? reviewCount,
    bool? isAIGenerated,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      dietaryTypes: dietaryTypes ?? this.dietaryTypes,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      videoUrl: videoUrl ?? this.videoUrl,
      authorId: authorId ?? this.authorId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class Ingredient {
  final String name;
  final String quantity;
  final String unit;
  final String? notes;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
    };
  }
}

