import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class SocialService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all posts
  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get user posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Get post by ID
  Stream<PostModel?> getPostById(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return PostModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // Get post by ID (one-time fetch)
  Future<PostModel?> getPostByIdOnce(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (doc.exists) {
      return PostModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Create post
  Future<String> createPost({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    File? mediaFile,
    String? mediaType,
  }) async {
    final docRef = _firestore.collection('posts').doc();
    String? mediaUrl;

    if (mediaFile != null) {
      mediaUrl = await _uploadMedia(docRef.id, mediaFile);
    }

    final post = PostModel(
      id: docRef.id,
      authorId: userId,
      authorName: userName,
      authorPhotoUrl: userPhotoUrl,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType ?? 'image',
      likes: [],
      commentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(post.toJson());
    notifyListeners();
    return docRef.id;
  }

  // Update post
  Future<void> updatePost({
    required String postId,
    required String content,
    File? mediaFile,
    String? mediaType,
  }) async {
    String? mediaUrl;

    if (mediaFile != null) {
      mediaUrl = await _uploadMedia(postId, mediaFile);
    }

    final data = {
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (mediaUrl != null) {
      data['mediaUrl'] = mediaUrl;
      data['mediaType'] = mediaType as Object;
    }

    await _firestore.collection('posts').doc(postId).update(data);
    notifyListeners();
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();

    // Delete associated media
    try {
      await _storage.ref('posts/$postId').delete();
    } catch (e) {
      // Ignore if media doesn't exist
    }

    // Delete associated comments
    final commentsQuery = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in commentsQuery.docs) {
      await doc.reference.delete();
    }

    notifyListeners();
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();

    if (!postDoc.exists) {
      return;
    }

    final post = PostModel.fromJson(postDoc.data()!);
    final likes = List<String>.from(post.likes);

    if (likes.contains(userId)) {
      // Unlike
      await unlikePost(postId, userId);
    } else {
      // Like
      await likePost(postId, userId);
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // Get post comments
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Add comment
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
  }) async {
    final docRef = _firestore.collection('comments').doc();

    final comment = CommentModel(
      id: docRef.id,
      postId: postId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      content: content,
      likes: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(comment.toJson());

    // Update post comment count
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
    return docRef.id;
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    final commentDoc = await _firestore.collection('comments').doc(commentId).get();
    if (commentDoc.exists) {
      final comment = CommentModel.fromJson(commentDoc.data()!);

      // Delete comment
      await commentDoc.reference.delete();

      // Update post comment count
      await _firestore.collection('posts').doc(comment.postId).update({
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    }
  }

  // Toggle like on a comment
  Future<void> toggleCommentLike(String commentId, String userId) async {
    final commentDoc = await _firestore.collection('comments').doc(commentId).get();

    if (!commentDoc.exists) {
      return;
    }

    final comment = CommentModel.fromJson(commentDoc.data()!);
    final likes = List<String>.from(comment.likes);

    if (likes.contains(userId)) {
      // Unlike
      await unlikeComment(commentId, userId);
    } else {
      // Like
      await likeComment(commentId, userId);
    }
  }

  // Like comment
  Future<void> likeComment(String commentId, String userId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'likes': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // Unlike comment
  Future<void> unlikeComment(String commentId, String userId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'likes': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    // Search in content and author name
    final contentResults = await _firestore
        .collection('posts')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + 'z')
        .get();

    final authorResults = await _firestore
        .collection('posts')
        .where('authorName', isGreaterThanOrEqualTo: query)
        .where('authorName', isLessThan: query + 'z')
        .get();

    final posts = [...contentResults.docs, ...authorResults.docs]
        .map((doc) => PostModel.fromJson(doc.data()))
        .toList();

    // Remove duplicates
    return posts.toSet().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Upload media
  Future<String> _uploadMedia(String postId, File mediaFile) async {
    final ref = _storage.ref().child('posts/$postId');
    final uploadTask = ref.putFile(mediaFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

