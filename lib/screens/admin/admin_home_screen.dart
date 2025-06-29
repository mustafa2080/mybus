import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/absence_model.dart';
import 'system_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Dashboard Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildDashboardCards(),
          ),

          // Management Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildManagementOptions(),
          ),

          const SizedBox(height: 20),

          // Quick Stats Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildQuickStatsSection(),
          ),

          const SizedBox(height: 20),

          // Recent Activity Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRecentActivitySection(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final totalStudents = students.length;
        final studentsOnBus = students.where((s) => s.currentStatus == StudentStatus.onBus).length;
        final studentsAtSchool = students.where((s) => s.currentStatus == StudentStatus.atSchool).length;

        return Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'إجمالي الطلاب',
                value: '$totalStudents',
                icon: Icons.school,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'في الباص',
                value: '$studentsOnBus',
                icon: Icons.directions_bus,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                title: 'في المدرسة',
                value: '$studentsAtSchool',
                icon: Icons.location_on,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25), // 0.1 * 255 = 25
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOptions() {
    return _buildManagementSection();
  }

  Widget _buildManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20), // 0.08 * 255 = 20
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
                  color: const Color(0xFF1E88E5).withAlpha(25), // 0.1 * 255 = 25
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إدارة النظام',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildManagementCard(
                icon: Icons.backup,
                label: 'نسخ احتياطي',
                description: 'حفظ واستعادة البيانات',
                color: const Color(0xFF2196F3),
                onTap: () => _showBackupDialog(),
              ),
              _buildManagementCard(
                icon: Icons.notifications_active,
                label: 'مركز الإشعارات',
                description: 'إدارة وإرسال الإشعارات',
                color: const Color(0xFFFF9800),
                onTap: () => context.push('/admin/notifications'),
              ),
              _buildManagementCard(
                icon: Icons.settings,
                label: 'إعدادات النظام',
                description: 'تكوين التطبيق',
                color: const Color(0xFF9C27B0),
                onTap: () => _showSystemSettings(),
              ),

              _buildManagementCard(
                icon: Icons.feedback,
                label: 'الشكاوى',
                description: 'إدارة شكاوى أولياء الأمور',
                color: const Color(0xFFFF5722),
                onTap: () => context.push('/admin/complaints'),
              ),
              _buildManagementCard(
                icon: Icons.poll,
                label: 'تقارير الاستبيانات',
                description: 'تقييم المشرفين وسلوك الطلاب',
                color: const Color(0xFF4CAF50),
                onTap: () => context.push('/admin/surveys-reports'),
              ),
              _buildManagementCard(
                icon: Icons.person_off,
                label: 'إدارة الغياب',
                description: 'موافقة طلبات الغياب والإحصائيات',
                color: const Color(0xFFE91E63),
                onTap: () => context.push('/admin/absence-management'),
              ),
              _buildManagementCard(
                icon: Icons.directions_bus,
                label: 'إدارة السيارات',
                description: 'إضافة وتعديل السيارات والسائقين',
                color: const Color(0xFF4CAF50),
                onTap: () => context.push('/admin/buses-management'),
              ),
              _buildManagementCard(
                icon: Icons.assignment_ind,
                label: 'تعيينات المشرفين',
                description: 'ربط المشرفين بالسيارات وإدارة الطوارئ',
                color: const Color(0xFF1E88E5),
                onTap: () => context.push('/admin/supervisor-assignments'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('النسخ الاحتياطي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إدارة النسخ الاحتياطية للبيانات'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _createBackup();
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('إنشاء نسخة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _restoreBackup();
                    },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('استعادة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء النسخة الاحتياطية...'),
        backgroundColor: Colors.blue,
      ),
    );
    // هنا يمكن إضافة منطق النسخ الاحتياطي الفعلي
  }

  void _restoreBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري استعادة النسخة الاحتياطية...'),
        backgroundColor: Colors.orange,
      ),
    );
    // هنا يمكن إضافة منطق الاستعادة الفعلي
  }

  void _showNotificationDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('إرسال إشعار جماعي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إرسال إشعار لجميع أولياء الأمور'),
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
              if (messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendNotification(messageController.text);
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _sendNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الإشعار: $message'),
        backgroundColor: Colors.green,
      ),
    );
    // هنا يمكن إضافة منطق إرسال الإشعارات الفعلي
  }

  void _showSystemSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SystemSettingsScreen(),
      ),
    );
  }





  // دالة لبناء قسم الإحصائيات السريعة
  Widget _buildQuickStatsSection() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(20), // 0.08 * 255 = 20
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
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      'الطلاب النشطون',
                      '${students.where((s) => s.isActive).length}',
                      Icons.people_alt,
                      Colors.blue,
                      '${students.isNotEmpty ? (students.where((s) => s.isActive).length / students.length * 100).toStringAsFixed(1) : 0}% من الإجمالي',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      'في الطريق',
                      '${students.where((s) => s.currentStatus == StudentStatus.onBus).length}',
                      Icons.directions_bus,
                      Colors.orange,
                      'طلاب في الحافلات',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      'وصلوا المدرسة',
                      '${students.where((s) => s.currentStatus == StudentStatus.atSchool).length}',
                      Icons.school,
                      Colors.green,
                      'طلاب في المدرسة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      'غير نشطين',
                      '${students.where((s) => !s.isActive).length}',
                      Icons.person_off,
                      Colors.purple,
                      'طلاب غير نشطين',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة لبناء بطاقة إحصائية سريعة
  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // دالة لبناء قسم النشاط الأخير
  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
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
                  color: Colors.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'النشاط الأخير',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/admin/reports'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // قائمة النشاطات الأخيرة من قاعدة البيانات
          StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getRecentAbsenceNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildActivityItem(
                  'لا توجد أنشطة حديثة',
                  'اليوم',
                  Icons.info,
                  Colors.grey,
                );
              }

              final recentActivities = snapshot.data!.take(4).toList();
              return Column(
                children: recentActivities.map((absence) {
                  return Column(
                    children: [
                      _buildActivityItem(
                        'طلب غياب من ${absence.studentName}',
                        _getTimeAgo(absence.createdAt),
                        Icons.person_off,
                        _getAbsenceStatusColor(absence.status),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // أزرار الإجراءات السريعة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/admin/reports'),
                  icon: const Icon(Icons.assessment, size: 18),
                  label: const Text('التقارير'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  // دالة لبناء عنصر نشاط
  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دالة لحساب الوقت المنقضي
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  // دالة لتحديد لون حالة الغياب
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
}


