import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const Center(child: Text('User data not found'));
          }

          return StreamBuilder<List<NotificationModel>>(
            stream: notificationService.getUserNotifications(userData.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll notify you when something important happens',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(context, notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final theme = Theme.of(context);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: theme.colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            notificationService.markAsRead(notification.id);
          }

          // Navigate based on notification type
          if (notification.type == 'recipe') {
            Navigator.pushNamed(
              context,
              '/recipe-details',
              arguments: notification.relatedId,
            );
          } else if (notification.type == 'social') {
            Navigator.pushNamed(
              context,
              '/post-details',
              arguments: notification.relatedId,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type, theme).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type, theme),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Mark as Read Button
              if (!notification.isRead)
                IconButton(
                  icon: const Icon(Icons.circle, size: 12),
                  color: theme.colorScheme.primary,
                  onPressed: () {
                    notificationService.markAsRead(notification.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'recipe':
        return Icons.restaurant;
      case 'social':
        return Icons.people;
      case 'inventory':
        return Icons.inventory_2;
      case 'meal_plan':
        return Icons.calendar_today;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, ThemeData theme) {
    switch (type) {
      case 'recipe':
        return theme.colorScheme.primary;
      case 'social':
        return theme.colorScheme.secondary;
      case 'inventory':
        return Colors.orange;
      case 'meal_plan':
        return Colors.green;
      case 'system':
        return Colors.blue;
      default:
        return theme.colorScheme.primary;
    }
  }
}
