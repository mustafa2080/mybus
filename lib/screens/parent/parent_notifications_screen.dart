import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../utils/notification_test_helper.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _databaseService.markAllNotificationsAsRead(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر اختبار الإشعارات (للتطوير فقط)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => NotificationTestHelper.showQuickTestMenu(context),
            tooltip: 'اختبار الإشعارات',
          ),
          StreamBuilder<int>(
            stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: _markAllAsRead,
                  tooltip: 'تحديد الكل كمقروء',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _databaseService.getParentNotifications(_authService.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ في تحميل الإشعارات: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ستظهر الإشعارات الجديدة هنا',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // تسجيل تشخيصي لفهم محتوى الإشعار
    debugPrint('🔍 Notification Debug:');
    debugPrint('  - ID: ${notification.id}');
    debugPrint('  - Title: "${notification.title}"');
    debugPrint('  - Body: "${notification.body}"');
    debugPrint('  - Body length: ${notification.body.length}');
    debugPrint('  - Type: ${notification.type}');
    debugPrint('  - IsRead: ${notification.isRead}');
    debugPrint('  - Data: ${notification.data}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead 
            ? BorderSide.none 
            : BorderSide(color: Colors.blue.withAlpha(76), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: notification.isRead ? Colors.white : Colors.blue.withAlpha(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Body
              Text(
                notification.body.isNotEmpty ? notification.body : 'لا يوجد محتوى للإشعار',
                style: TextStyle(
                  fontSize: 14,
                  color: notification.body.isNotEmpty ? Colors.grey[700] : Colors.red[400],
                  height: 1.4,
                  fontStyle: notification.body.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                ),
              ),
              
              // Student info if available
              if (notification.studentName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'الطالب: ${notification.studentName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
        return Colors.green;
      case NotificationType.studentLeft:
        return Colors.orange;
      case NotificationType.tripStarted:
        return Colors.blue;
      case NotificationType.tripEnded:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
        return Icons.directions_bus;
      case NotificationType.studentLeft:
        return Icons.home;
      case NotificationType.tripStarted:
        return Icons.play_arrow;
      case NotificationType.tripEnded:
        return Icons.stop;
      case NotificationType.general:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd').format(timestamp);
    }
  }
}
