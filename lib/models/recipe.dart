class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int cookTime;
  final int calories;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final Map<String, double> nutrition;
  final String userId;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cookTime,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    required this.nutrition,
    required this.userId,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      cookTime: json['cookTime'],
      calories: json['calories'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      tags: List<String>.from(json['tags']),
      nutrition: Map<String, double>.from(json['nutrition']),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'cookTime': cookTime,
      'calories': calories,
      'ingredients': ingredients,
      'instructions': instructions,
      'tags': tags,
      'nutrition': nutrition,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

