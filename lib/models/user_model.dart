import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final Map<String, dynamic>? healthGoals;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.healthGoals,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle potential type issues with dietaryPreferences and allergies
    List<String> parseDietaryPreferences() {
      final prefs = json['dietaryPreferences'];
      if (prefs == null) return [];
      if (prefs is List) {
        return List<String>.from(prefs.map((item) => item.toString()));
      }
      return [];
    }

    List<String> parseAllergies() {
      final allergies = json['allergies'];
      if (allergies == null) return [];
      if (allergies is List) {
        return List<String>.from(allergies.map((item) => item.toString()));
      }
      return [];
    }

    Map<String, dynamic>? parseHealthGoals() {
      final goals = json['healthGoals'];
      if (goals == null) return {};
      if (goals is Map) {
        return Map<String, dynamic>.from(goals);
      }
      return {};
    }

    // Handle Timestamp conversion safely
    DateTime parseTimestamp(dynamic timestamp, DateTime defaultValue) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return defaultValue;
    }

    final now = DateTime.now();

    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      dietaryPreferences: parseDietaryPreferences(),
      allergies: parseAllergies(),
      healthGoals: parseHealthGoals(),
      createdAt: parseTimestamp(json['createdAt'], now),
      lastUpdated: parseTimestamp(json['lastUpdated'], now),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'healthGoals': healthGoals,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    Map<String, dynamic>? healthGoals,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      healthGoals: healthGoals ?? this.healthGoals,
      createdAt: this.createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}

