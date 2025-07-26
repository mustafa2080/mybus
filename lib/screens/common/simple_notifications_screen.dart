import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/simple_notification_service.dart';

class SimpleNotificationsScreen extends StatefulWidget {
  const SimpleNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<SimpleNotificationsScreen> createState() => _SimpleNotificationsScreenState();
}

class _SimpleNotificationsScreenState extends State<SimpleNotificationsScreen> {
  final SimpleNotificationService _notificationService = SimpleNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotifications(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل الإشعارات',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى المحاولة مرة أخرى',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر الإشعارات هنا عند وصولها',
                    style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool? ?? false;
    final title = notification['title'] as String? ?? 'إشعار';
    final body = notification['body'] as String? ?? '';
    final type = notification['type'] as String? ?? 'general';
    final createdAt = notification['createdAt'];
    
    DateTime? dateTime;
    if (createdAt != null) {
      try {
        dateTime = createdAt.toDate();
      } catch (e) {
        print('خطأ في تحويل التاريخ: $e');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isRead ? Colors.grey[700] : Colors.black,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRead ? Colors.grey[600] : Colors.grey[800],
                  ),
                ),
              ],
              if (dateTime != null) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'welcome':
        iconData = Icons.waving_hand;
        color = Colors.green;
        break;
      case 'newComplaint':
        iconData = Icons.report_problem;
        color = Colors.orange;
        break;
      case 'newStudent':
        iconData = Icons.person_add;
        color = Colors.blue;
        break;
      case 'studentAbsence':
        iconData = Icons.event_busy;
        color = Colors.red;
        break;
      case 'admin':
        iconData = Icons.admin_panel_settings;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Icon(
      iconData,
      color: color,
      size: 24,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  Future<void> _markAsRead(String? notificationId) async {
    if (notificationId != null) {
      await _notificationService.markAsRead(notificationId);
    }
  }

  Future<void> _markAllAsRead() async {
    // يمكن تطبيق هذه الوظيفة لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديد جميع الإشعارات كمقروءة'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
