import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.likes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      userName: json['userName'],
      userPhotoUrl: json['userPhotoUrl'],
      content: json['content'],
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

