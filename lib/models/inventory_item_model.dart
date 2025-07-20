import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final DateTime purchaseDate;
  final String? notes;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.purchaseDate,
    this.notes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      quantity: json['quantity'].toDouble(),
      unit: json['unit'],
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] as Timestamp).toDate()
          : null,
      purchaseDate: (json['purchaseDate'] as Timestamp).toDate(),
      notes: json['notes'],
      userId: json['userId'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InventoryItemModel copyWith({
    String? name,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    String? notes,
  }) {
    return InventoryItemModel(
      id: this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      userId: this.userId,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

