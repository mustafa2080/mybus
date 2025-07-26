import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../models/notification_settings_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';

/// شاشة إدارة الإشعارات للأدمن مع عداد الإشعارات والإعدادات
class AdminNotificationsManagementScreen extends StatefulWidget {
  const AdminNotificationsManagementScreen({super.key});

  @override
  State<AdminNotificationsManagementScreen> createState() => _AdminNotificationsManagementScreenState();
}

class _AdminNotificationsManagementScreenState extends State<AdminNotificationsManagementScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  
  String? _currentUserId;
  NotificationSettingsModel? _userSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = authService.currentUser?.uid;
      
      if (_currentUserId != null) {
        _userSettings = await _notificationService.getUserNotificationSettings(_currentUserId!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإشعارات'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildSettingsTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendNotificationDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// تبويب الإشعارات
  Widget _buildNotificationsTab() {
    if (_currentUserId == null) {
      return const Center(child: Text('خطأ في تحميل بيانات المستخدم'));
    }

    return Column(
      children: [
        // عداد الإشعارات
        _buildNotificationCounter(),
        
        // قائمة الإشعارات
        Expanded(
          child: StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.getUserNotifications(_currentUserId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في تحميل الإشعارات: ${snapshot.error}'),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد إشعارات', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
        ),
      ],
    );
  }

  /// عداد الإشعارات
  Widget _buildNotificationCounter() {
    if (_currentUserId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإشعارات غير المقروءة',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                StreamBuilder<int>(
                  stream: _notificationService.getUnreadNotificationsCount(_currentUserId!),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count إشعار',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
    );
  }

  /// بطاقة الإشعار
  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = notification.isUnread;
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread ? Border.all(color: AppConstants.primaryColor, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityIcon(notification.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isUnread)
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
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      notification.typeDisplayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getTypeColor(notification.type).withOpacity(0.2),
                    side: BorderSide(color: _getTypeColor(notification.type)),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// أيقونة الأولوية
  Widget _buildPriorityIcon(NotificationPriority priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case NotificationPriority.urgent:
        icon = Icons.priority_high;
        color = Colors.red;
        break;
      case NotificationPriority.high:
        icon = Icons.arrow_upward;
        color = Colors.orange;
        break;
      case NotificationPriority.medium:
        icon = Icons.remove;
        color = Colors.blue;
        break;
      case NotificationPriority.low:
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  /// لون نوع الإشعار
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newComplaint:
        return Colors.red;
      case NotificationType.newStudent:
        return Colors.green;
      case NotificationType.studentAbsence:
        return Colors.orange;
      case NotificationType.supervisorEvaluation:
        return Colors.purple;
      default:
        return AppConstants.primaryColor;
    }
  }

  /// حساب الوقت المنقضي
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// تحديد الإشعار كمقروء
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isUnread) {
      await _notificationService.markNotificationAsRead(notification.id);
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> _markAllAsRead() async {
    if (_currentUserId != null) {
      final success = await _notificationService.markAllNotificationsAsRead(_currentUserId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// تبويب الإعدادات
  Widget _buildSettingsTab() {
    return const Center(child: Text('إعدادات الإشعارات - قيد التطوير'));
  }

  /// تبويب الإحصائيات
  Widget _buildStatisticsTab() {
    return const Center(child: Text('إحصائيات الإشعارات - قيد التطوير'));
  }

  /// حوار إرسال إشعار جديد
  void _showSendNotificationDialog() {
    // سيتم تطوير هذا لاحقاً
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال إشعار جديد'),
        content: const Text('هذه الميزة قيد التطوير'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
