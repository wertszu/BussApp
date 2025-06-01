import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final userId = authService.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final notifications = await dbService.getNotifications(userId);
      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке уведомлений'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.markNotificationAsRead(notification.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Уведомление отмечено как прочитанное'),
          duration: Duration(seconds: 2),
        ),
      );
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при обновлении уведомления'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.deleteNotification(notification.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Уведомление удалено'),
          duration: Duration(seconds: 2),
        ),
      );
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при удалении уведомления'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final userId = authService.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await dbService.clearNotifications(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все уведомления удалены'),
          duration: Duration(seconds: 2),
        ),
      );
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при удалении уведомлений'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _notifications.isEmpty) {
       _loadNotifications();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllNotifications,
              tooltip: 'Удалить все уведомления',
            ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'Нет уведомлений',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNotification(notification);
                      },
                      child: ListTile(
                        title: Text(notification.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(notification.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        leading: Icon(
                          notification.isRead
                              ? Icons.mark_email_read
                              : Icons.mark_email_unread,
                          color: notification.isRead
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        onTap: () {
                          if (!notification.isRead) {
                            _markAsRead(notification);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 