import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/supabase_notification_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../models/notification.dart' as models;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  final SupabaseNotificationService _notificationService = SupabaseNotificationService();
  List<models.Notification> _notifications = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }


  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      _notifications = await _notificationService.getUserNotifications(
        appState.currentUser!.id!,
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    _loadNotifications();
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      // Refresh unread count in app state if needed
    }
  }

  Future<void> _markAllAsRead() async {
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      await _notificationService.markAllAsRead(appState.currentUser!.id!);
      _loadNotifications();
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'review':
        return Icons.rate_review;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có thông báo nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id ?? ''),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _markAsRead(notification.id!);
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getNotificationColor(notification.type),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: notification.message != null
                              ? Text(notification.message!)
                              : null,
                          trailing: notification.isRead
                              ? null
                              : const Icon(Icons.circle, size: 8, color: Colors.blue),
                          onTap: () {
                            if (!notification.isRead) {
                              _markAsRead(notification.id!);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

