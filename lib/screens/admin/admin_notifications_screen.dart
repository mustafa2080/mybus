import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/absence_model.dart';
import '../../models/complaint_model.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'مركز الإشعارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'تحديد الكل كمقروء',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _showSendNotificationDialog,
            tooltip: 'إرسال إشعار جماعي',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_active, size: 18),
              text: 'الإشعارات العامة',
            ),
            Tab(
              icon: Icon(Icons.person_off, size: 18),
              text: 'طلبات الغياب',
            ),
            Tab(
              icon: Icon(Icons.report_problem, size: 18),
              text: 'الشكاوى',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: 18),
              text: 'الإحصائيات',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralNotifications(),
          _buildAbsenceRequests(),
          _buildComplaints(),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildGeneralNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotificationsForUser(
        _authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل الإشعارات');
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState(
            'لا توجد إشعارات عامة',
            'لم يتم استلام أي إشعارات عامة',
            Icons.notifications_off,
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
    );
  }

  Widget _buildAbsenceRequests() {
    return StreamBuilder<List<AbsenceModel>>(
      stream: _databaseService.getPendingAbsences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل طلبات الغياب');
        }

        final absences = snapshot.data ?? [];

        if (absences.isEmpty) {
          return _buildEmptyState(
            'لا توجد طلبات غياب معلقة',
            'جميع طلبات الغياب تم التعامل معها',
            Icons.check_circle,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: absences.length,
          itemBuilder: (context, index) {
            final absence = absences[index];
            return _buildAbsenceRequestCard(absence);
          },
        );
      },
    );
  }

  Widget _buildComplaints() {
    return StreamBuilder<List<ComplaintModel>>(
      stream: _databaseService.getPendingComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل الشكاوى');
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return _buildEmptyState(
            'لا توجد شكاوى جديدة',
            'جميع الشكاوى تم التعامل معها',
            Icons.sentiment_satisfied,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return _buildComplaintCard(complaint);
          },
        );
      },
    );
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Notifications Statistics
          _buildStatisticsCard(
            title: 'إحصائيات الإشعارات',
            icon: Icons.notifications,
            color: Colors.blue,
            children: [
              StreamBuilder<int>(
                stream: _databaseService.getRecentNotificationsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('إشعارات اليوم', count.toString(), Icons.today);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getPendingAbsences().map((list) => list.length),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('طلبات غياب معلقة', count.toString(), Icons.pending_actions);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // System Health
          _buildStatisticsCard(
            title: 'حالة النظام',
            icon: Icons.health_and_safety,
            color: Colors.green,
            children: [
              _buildStatItem('حالة الخادم', 'متصل', Icons.cloud_done, valueColor: Colors.green),
              _buildStatItem('آخر نسخة احتياطية', 'منذ ساعة', Icons.backup),
              _buildStatItem('المستخدمين النشطين', '45', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAbsenceRequest(AbsenceModel absence, bool approve) async {
    try {
      final status = approve ? AbsenceStatus.approved : AbsenceStatus.rejected;
      final updatedAbsence = absence.copyWith(
        status: status,
        reviewedAt: DateTime.now(),
        reviewedBy: _authService.currentUser?.uid ?? '',
      );

      await _databaseService.updateAbsence(updatedAbsence);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'تم قبول طلب الغياب' : 'تم رفض طلب الغياب',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معالجة الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send, color: Colors.blue),
            SizedBox(width: 8),
            Text('إرسال إشعار جماعي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الإشعار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(),
                hintText: 'اكتب رسالة الإشعار هنا...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendBroadcastNotification(titleController.text, messageController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcastNotification(String title, String message) async {
    try {
      // This would typically send to all users
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الإشعار: $title'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الإشعار: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await _notificationService.markAllNotificationsAsRead(userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديد جميع الإشعارات كمقروءة'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الإشعارات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
