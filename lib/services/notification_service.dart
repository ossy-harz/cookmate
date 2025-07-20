import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Add a notification
  Future<void> addNotification(NotificationModel notification) {
    return _firestore.collection('notifications').add(notification.toMap());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) {
    return _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    return batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Create a system notification
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String body,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'system',
      createdAt: DateTime.now(),
    );

    return addNotification(notification);
  }

  // Create a recipe notification
  Future<void> createRecipeNotification({
    required String userId,
    required String title,
    required String body,
    required String recipeId,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'recipe',
      relatedId: recipeId,
      createdAt: DateTime.now(),
    );

    return addNotification(notification);
  }

  // Create a social notification
  Future<void> createSocialNotification({
    required String userId,
    required String title,
    required String body,
    required String postId,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'social',
      relatedId: postId,
      createdAt: DateTime.now(),
    );

    return addNotification(notification);
  }

  // Create an inventory notification
  Future<void> createInventoryNotification({
    required String userId,
    required String title,
    required String body,
    String? itemId,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'inventory',
      relatedId: itemId,
      createdAt: DateTime.now(),
    );

    return addNotification(notification);
  }

  // Create a meal plan notification
  Future<void> createMealPlanNotification({
    required String userId,
    required String title,
    required String body,
    String? mealPlanId,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'meal_plan',
      relatedId: mealPlanId,
      createdAt: DateTime.now(),
    );

    return addNotification(notification);
  }
}
