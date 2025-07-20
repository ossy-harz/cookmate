import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String? mediaUrl;
  final String mediaType; // 'image' or 'video'
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.mediaUrl,
    required this.mediaType,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      authorPhotoUrl: json['authorPhotoUrl'],
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'] ?? 'image',
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    String? mediaUrl,
    String? mediaType,
    List<String>? likes,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

