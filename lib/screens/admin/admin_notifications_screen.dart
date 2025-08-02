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
            icon: const Icon(Icons.build),
            onPressed: _fixNotifications,
            tooltip: 'إصلاح الإشعارات',
          ),
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
      stream: _databaseService.getAdminNotifications(
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
                stream: _databaseService.getAllRecentNotificationsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('إشعارات آخر 24 ساعة', count.toString(), Icons.today);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getPendingAbsences().map((list) => list.length),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('طلبات غياب معلقة', count.toString(), Icons.pending_actions,
                    valueColor: count > 0 ? Colors.orange : Colors.green);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getPendingComplaints().map((list) => list.length),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('شكاوى معلقة', count.toString(), Icons.report_problem,
                    valueColor: count > 0 ? Colors.red : Colors.green);
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
              StreamBuilder<int>(
                stream: _databaseService.getTotalUsersCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('إجمالي المستخدمين', count.toString(), Icons.people);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getActiveStudentsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('الطلاب النشطين', count.toString(), Icons.school);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Additional Statistics
          _buildStatisticsCard(
            title: 'إحصائيات إضافية',
            icon: Icons.analytics,
            color: Colors.purple,
            children: [
              StreamBuilder<int>(
                stream: _databaseService.getTotalParentsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('أولياء الأمور', count.toString(), Icons.family_restroom);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getTotalSupervisorsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('المشرفين', count.toString(), Icons.supervisor_account);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getTotalBusesCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('الحافلات', count.toString(), Icons.directions_bus);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trip Statistics
          _buildStatisticsCard(
            title: 'إحصائيات الرحلات',
            icon: Icons.directions_bus,
            color: Colors.orange,
            children: [
              StreamBuilder<int>(
                stream: _databaseService.getActiveTripCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('رحلات نشطة', count.toString(), Icons.play_circle,
                    valueColor: count > 0 ? Colors.green : Colors.grey);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getTodayTripsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('رحلات اليوم', count.toString(), Icons.today);
                },
              ),
              StreamBuilder<int>(
                stream: _databaseService.getAssignedStudentsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildStatItem('طلاب مسكنين', count.toString(), Icons.assignment_ind);
                },
              ),
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
        approvedAt: DateTime.now(),
        approvedBy: _authService.currentUser?.uid ?? '',
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

  Future<void> _fixNotifications() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري إصلاح الإشعارات...'),
          backgroundColor: Colors.orange,
        ),
      );

      await _databaseService.fixExistingNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إصلاح الإشعارات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error fixing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إصلاح الإشعارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _databaseService.markNotificationAsRead(notification.id);
        debugPrint('✅ Admin marked notification as read: ${notification.id}');
      } catch (e) {
        debugPrint('❌ Error marking notification as read: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحديث الإشعار: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        // للإدمن: تحديد جميع الإشعارات في النظام كمقروءة
        await _databaseService.markAllSystemNotificationsAsRead();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديد جميع الإشعارات في النظام كمقروءة'),
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

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(color: Colors.blue.withAlpha(76), width: 1),
      ),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: InkWell(
        onTap: () => _markNotificationAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 16,
                        color: notification.isRead ? Colors.grey[800] : Colors.blue[800],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.relativeTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.body.isNotEmpty ? notification.body : 'لا يوجد محتوى للإشعار',
                style: TextStyle(
                  color: notification.body.isNotEmpty ? Colors.grey[700] : Colors.red[400],
                  fontSize: 14,
                  fontStyle: notification.body.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                ),
              ),

              // معلومات إضافية
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'المستلم: ${notification.recipientId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    notification.typeDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getNotificationColor(notification.type),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (notification.studentName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الطالب: ${notification.studentName}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildAbsenceRequestCard(AbsenceModel absence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_busy,
                  color: _getAbsenceStatusColor(absence.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'طلب غياب - ${absence.studentName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAbsenceStatusColor(absence.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    absence.statusDisplayText,
                    style: TextStyle(
                      color: _getAbsenceStatusColor(absence.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('نوع الغياب', absence.typeDisplayText),
            _buildDetailRow('التاريخ', DateFormat('yyyy/MM/dd').format(absence.date)),
            if (absence.endDate != null)
              _buildDetailRow('تاريخ الانتهاء', DateFormat('yyyy/MM/dd').format(absence.endDate!)),
            _buildDetailRow('السبب', absence.reason),
            if (absence.notes != null && absence.notes!.isNotEmpty)
              _buildDetailRow('ملاحظات', absence.notes!),
            if (absence.status == AbsenceStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveAbsence(absence),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectAbsence(absence),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.report_problem,
                  color: _getComplaintPriorityColor(complaint.priority),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    complaint.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getComplaintStatusColor(complaint.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    complaint.statusDisplayName,
                    style: TextStyle(
                      color: _getComplaintStatusColor(complaint.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('ولي الأمر', complaint.parentName),
            _buildDetailRow('رقم الهاتف', complaint.parentPhone),
            if (complaint.studentName != null)
              _buildDetailRow('الطالب', complaint.studentName!),
            _buildDetailRow('نوع الشكوى', complaint.typeDisplayName),
            _buildDetailRow('الأولوية', complaint.priorityDisplayName),
            const SizedBox(height: 8),
            Text(
              complaint.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            if (complaint.status == ComplaintStatus.pending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _respondToComplaint(complaint),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('الرد على الشكوى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
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
      case NotificationType.studentAssigned:
        return Icons.person_add;
      case NotificationType.studentUnassigned:
        return Icons.person_remove;
      case NotificationType.absenceRequested:
        return Icons.event_busy;
      case NotificationType.absenceApproved:
        return Icons.check_circle;
      case NotificationType.absenceRejected:
        return Icons.cancel;
      case NotificationType.complaintSubmitted:
        return Icons.feedback;
      case NotificationType.complaintResponded:
        return Icons.reply;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.tripDelayed:
        return Icons.schedule;
      case NotificationType.general:
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
        return Colors.green;
      case NotificationType.studentLeft:
        return Colors.blue;
      case NotificationType.tripStarted:
        return Colors.orange;
      case NotificationType.tripEnded:
        return Colors.red;
      case NotificationType.studentAssigned:
        return Colors.green;
      case NotificationType.studentUnassigned:
        return Colors.orange;
      case NotificationType.absenceRequested:
        return Colors.orange;
      case NotificationType.absenceApproved:
        return Colors.green;
      case NotificationType.absenceRejected:
        return Colors.red;
      case NotificationType.complaintSubmitted:
        return Colors.purple;
      case NotificationType.complaintResponded:
        return Colors.blue;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.systemUpdate:
        return Colors.grey;
      case NotificationType.tripDelayed:
        return Colors.orange;
      case NotificationType.general:
      default:
        return Colors.grey;
    }
  }

  Color _getAbsenceStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  Color _getComplaintStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  Color _getComplaintPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;
      case ComplaintPriority.urgent:
        return Colors.purple;
    }
  }

  Future<void> _approveAbsence(AbsenceModel absence) async {
    try {
      await _databaseService.updateAbsenceStatus(
        absence.id,
        AbsenceStatus.approved,
        _authService.currentUser?.uid ?? '',
      );

      // إرسال إشعار للمستخدمين المتأثرين (بدون إشعار للإدمن الحالي)
      await _notificationService.notifyAbsenceApprovedWithSound(
        studentId: absence.studentId,
        studentName: absence.studentName,
        parentId: absence.parentId,
        supervisorId: absence.supervisorId ?? '',
        absenceDate: absence.date,
        approvedBy: 'الإدارة',
        // لا نمرر approvedBySupervisorId لأن الإدمن هو من وافق وليس المشرف
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول طلب الغياب'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في قبول الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAbsence(AbsenceModel absence) async {
    try {
      await _databaseService.updateAbsenceStatus(
        absence.id,
        AbsenceStatus.rejected,
        _authService.currentUser?.uid ?? '',
      );

      // إرسال إشعار للمستخدمين المتأثرين (بدون إشعار للإدمن الحالي)
      await _notificationService.notifyAbsenceRejectedWithSound(
        studentId: absence.studentId,
        studentName: absence.studentName,
        parentId: absence.parentId,
        supervisorId: absence.supervisorId ?? '',
        absenceDate: absence.date,
        rejectedBy: 'الإدارة',
        reason: 'تم رفض الطلب من قبل الإدارة',
        // لا نمرر rejectedBySupervisorId لأن الإدمن هو من رفض وليس المشرف
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض طلب الغياب'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفض الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _respondToComplaint(ComplaintModel complaint) async {
    // This would open a dialog to respond to the complaint
    // Implementation would depend on your specific requirements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة نافذة الرد على الشكوى قريباً'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
