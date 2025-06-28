import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/absence_model.dart';
import '../../models/student_model.dart';
import '../../widgets/curved_app_bar.dart';
import 'school_info_screen.dart';

class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedCurvedAppBar(
        title: 'باصي - المشرف',
        subtitle: const Text('إدارة رحلات الطلاب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        height: 240,
        actions: [
          // إشعار طلبات الغياب والإشعارات العامة
          StreamBuilder<int>(
            stream: _databaseService.getRecentNotificationsCount(),
            builder: (context, snapshot) {
              // Add debug information
              debugPrint('🔔 Notification StreamBuilder - Connection: ${snapshot.connectionState}, Data: ${snapshot.data}, Error: ${snapshot.error}');

              final notificationCount = snapshot.data ?? 0;
              final hasNotifications = notificationCount > 0;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        hasNotifications ? Icons.notifications_active : Icons.notifications,
                        color: hasNotifications ? Colors.yellow : Colors.white,
                      ),
                      onPressed: () => context.push('/supervisor/notifications'),
                      tooltip: hasNotifications
                          ? '$notificationCount إشعار جديد'
                          : 'الإشعارات',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (hasNotifications)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notificationCount > 99 ? '99+' : notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),



          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupervisorSchoolInfoScreen(),
                ),
              );
            },
            tooltip: 'معلومات المدرسة',
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/supervisor/profile');
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('الملف الشخصي'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [


            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildQRScannerButton(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStudentsListButton(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAbsenceManagementButton(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmergencyContactButton(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSurveysButton(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // تنبيه إشعارات الغياب الجديدة
            StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getRecentAbsenceNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final notificationCount = snapshot.data?.length ?? 0;

                if (notificationCount == 0) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withAlpha(25),
                        Colors.indigo.withAlpha(25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ًں“¢ إشعار: $notificationCount إبلاغ غياب جديد',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'تم إبلاغ المدرسة عن غيابات جديدة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showTodayAbsences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'عرض',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),


          ],
        ),
      ),

    );
  }



  Widget _buildQRScannerButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 40,
            color: Color(0xFF1E88E5),
          ),
          const SizedBox(height: 8),
          const Text(
            'مسح الباركود',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'مسح باركود الطالب',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
              label: const Text(
                'بدء المسح',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsListButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 40,
            color: Color(0xFFFF9800),
          ),
          const SizedBox(height: 8),
          const Text(
            'قائمة الطلاب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'عرض الطلاب وأكواد QR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/students-list'),
              icon: const Icon(Icons.people, color: Colors.white, size: 16),
              label: const Text(
                'عرض القائمة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اتصال الطوارئ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/emergency-contact'),
              icon: const Icon(Icons.phone, color: Colors.white, size: 16),
              label: const Text(
                'أرقام الطوارئ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'الاستبيانات الشهرية',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/surveys'),
              icon: const Icon(Icons.poll, color: Colors.white, size: 16),
              label: const Text(
                'عرض الاستبيانات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceManagementButton() {
    return StreamBuilder<List<AbsenceModel>>(
      stream: _databaseService.getPendingAbsences(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: pendingCount > 0
                ? Border.all(color: Colors.orange.withAlpha(127), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: pendingCount > 0
                    ? Colors.orange.withAlpha(51)
                    : Colors.grey.withAlpha(20),
                blurRadius: pendingCount > 0 ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'إدارة الغياب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pendingCount > 0
                    ? '$pendingCount طلب غياب في الانتظار'
                    : 'تسجيل غياب الطلاب ومتابعة الحالات',
                style: TextStyle(
                  color: pendingCount > 0 ? Colors.orange : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAbsenceRegistration,
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text(
                        'تسجيل غياب',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showTodayAbsences,
                      icon: Icon(
                        pendingCount > 0 ? Icons.notification_important : Icons.list,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        pendingCount > 0 ? 'طلبات ($pendingCount)' : 'الغيابات اليوم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pendingCount > 0 ? Colors.orange : const Color(0xFF9C27B0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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







  void _scanQRCode() {
    context.push('/supervisor/qr-scanner');
  }



  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة لعرض تسجيل الغياب
  void _showAbsenceRegistration() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_disabled, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تسجيل غياب طالب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<StudentModel>>(
                  stream: _databaseService.getAllStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لا يوجد طلاب',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    final students = snapshot.data!;
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withAlpha(51)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                // صورة الطالب - أصغر
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.red.withAlpha(76)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // معلومات الطالب - مضغوطة
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student.grade} • ${student.busRoute}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // زر تسجيل الغياب - أصغر
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _registerStudentAbsence(student);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_off,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'غياب',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لعرض غيابات اليوم وطلبات الغياب
  void _showTodayAbsences() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_off, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'إدارة الغياب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TabBar(
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.purple,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.notifications, size: 20),
                        text: 'إشعارات الغياب',
                      ),
                      Tab(
                        icon: Icon(Icons.check_circle, size: 20),
                        text: 'غيابات اليوم',
                      ),
                      Tab(
                        icon: Icon(Icons.list_alt, size: 20),
                        text: 'جميع الإشعارات',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // إحصائيات سريعة مضغوطة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(13),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.withAlpha(51)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<AbsenceModel>>(
                          stream: _databaseService.getRecentAbsenceNotifications(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return _buildCompactStat('إشعارات جديدة', count.toString(), Icons.notifications, Colors.blue);
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.withAlpha(76),
                      ),
                      Expanded(
                        child: StreamBuilder<List<AbsenceModel>>(
                          stream: _databaseService.getTodayAbsences(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return _buildCompactStat('غيابات اليوم', count.toString(), Icons.person_off, Colors.red);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // إشعارات الغياب الجديدة
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getRecentAbsenceNotifications(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد إشعارات جديدة',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'لم يتم إرسال إشعارات غياب في آخر 24 ساعة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final recentNotifications = snapshot.data!;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 1000,
                            itemCount: recentNotifications.length,
                            itemBuilder: (context, index) {
                              final absence = recentNotifications[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withAlpha(76)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header مضغوط
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withAlpha(25),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: const Icon(
                                              Icons.schedule,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  absence.studentName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  absence.typeDisplayText,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'معلق',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // السبب مضغوط
                                      Text(
                                        'السبب: ${absence.reason}',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      if (absence.notes != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'ملاحظات: ${absence.notes}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],

                                      const SizedBox(height: 8),

                                      // معلومات إضافية
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'تم إبلاغ المدرسة عن هذا الغياب',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(absence.createdAt),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // غيابات اليوم
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getTodayAbsences(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد غيابات اليوم',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'جميع الطلاب حاضرون',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final absences = snapshot.data!;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 1000,
                            itemCount: absences.length,
                            itemBuilder: (context, index) {
                              final absence = absences[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getAbsenceStatusColor(absence.status).withAlpha(76),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header مضغوط
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Icon(
                                              _getAbsenceStatusIcon(absence.status),
                                              color: _getAbsenceStatusColor(absence.status),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  absence.studentName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${absence.typeDisplayText} • ${absence.sourceDisplayText}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getAbsenceStatusColor(absence.status),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  absence.statusDisplayText,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatTime(absence.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // السبب مضغوط
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'السبب: ${absence.reason}',
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (absence.notes != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'ملاحظات: ${absence.notes}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // جميع الطلبات (للتشخيص)
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getAllAbsencesStream(),
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
                                  Text('خطأ: ${snapshot.error}'),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد طلبات غياب',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'لم يتم إرسال أي طلبات بعد',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final allAbsences = snapshot.data!;
                          return Column(
                            children: [
                              // إحصائيات سريعة
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const Text(
                                            'إجمالي الطلبات',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.pending).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const Text(
                                            'معلقة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.approved).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const Text(
                                            'مقبولة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.rejected).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const Text(
                                            'مرفوضة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // قائمة جميع الطلبات
                              Expanded(
                                child: ListView.builder(
                                  itemCount: allAbsences.length,
                                  itemBuilder: (context, index) {
                                    final absence = allAbsences[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getAbsenceStatusColor(absence.status).withAlpha(76),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            _getAbsenceStatusIcon(absence.status),
                                            color: _getAbsenceStatusColor(absence.status),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          absence.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${absence.typeDisplayText} • ${absence.sourceDisplayText}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'السبب: ${absence.reason}',
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'تاريخ الإنشاء: ${_formatTime(absence.createdAt)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getAbsenceStatusColor(absence.status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            absence.statusDisplayText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لتسجيل غياب طالب
  void _registerStudentAbsence(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_off, color: Colors.red),
            const SizedBox(width: 8),
            Text('تسجيل غياب ${student.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد تسجيل غياب الطالب ${student.name}؟'),
            const SizedBox(height: 16),
            const Text(
              'سيتم إرسال إشعار لولي الأمر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
            onPressed: () async {
              Navigator.pop(context);
              await _confirmAbsenceRegistration(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الغياب'),
          ),
        ],
      ),
    );
  }

  // دالة لتأكيد تسجيل الغياب
  Future<void> _confirmAbsenceRegistration(StudentModel student) async {
    try {
      final absenceData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'studentId': student.id,
        'studentName': student.name,
        'parentId': student.parentId,
        'type': 'other',
        'reason': 'غياب مسجل من قبل المشرف',
        'date': DateTime.now().toIso8601String(),
        'endDate': null,
        'isMultipleDays': false,
        'status': 'approved', // مقبول مباشرة من المشرف
        'notes': 'تم تسجيل الغياب من قبل المشرف أثناء الرحلة',
        'createdAt': DateTime.now().toIso8601String(),
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedBy': 'المشرف',
        'rejectionReason': null,
      };

      // إنشاء نموذج الغياب
      final now = DateTime.now();
      final absenceModel = AbsenceModel(
        id: absenceData['id'] as String,
        studentId: absenceData['studentId'] as String,
        studentName: absenceData['studentName'] as String,
        parentId: absenceData['parentId'] as String,
        supervisorId: null, // يمكن إضافة ID المشرف هنا
        adminId: null,
        type: AbsenceType.other,
        status: AbsenceStatus.approved,
        source: AbsenceSource.supervisor, // مصدر الغياب: المشرف
        date: DateTime.parse(absenceData['date'] as String),
        endDate: null,
        reason: absenceData['reason'] as String,
        notes: absenceData['notes'] as String?,
        attachmentUrl: null,
        createdAt: DateTime.parse(absenceData['createdAt'] as String),
        updatedAt: now, // وقت التحديث
        approvedBy: absenceData['approvedBy'] as String,
        approvedAt: DateTime.parse(absenceData['approvedAt'] as String),
        rejectionReason: null,
      );

      await _databaseService.createAbsence(absenceModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل غياب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // إرسال إشعار لولي الأمر
      await _notificationService.sendGeneralNotification(
        title: 'تسجيل غياب',
        body: 'تم تسجيل غياب ${student.name} من قبل المشرف',
        recipientId: student.parentId,
        data: {
          'type': 'absence_registered',
          'studentId': student.id,
          'studentName': student.name,
          'date': DateTime.now().toIso8601String(),
        },
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الغياب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دوال مساعدة لحالة الغياب
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

  IconData _getAbsenceStatusIcon(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Icons.schedule;
      case AbsenceStatus.approved:
        return Icons.check_circle;
      case AbsenceStatus.rejected:
        return Icons.cancel;
    }
  }



  // دالة لتنسيق الوقت
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // دالة لبناء إحصائية مضغوطة
  Widget _buildCompactStat(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لعرض جميع الإشعارات الحديثة
  void _showAllNotifications() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الإشعارات الحديثة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF1E88E5),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF1E88E5),
                        tabs: [
                          Tab(text: 'إشعارات الغياب'),
                          Tab(text: 'الإشعارات العامة'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // إشعارات الغياب
                            StreamBuilder<List<AbsenceModel>>(
                              stream: _databaseService.getRecentAbsenceNotifications(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text('لا توجد إشعارات غياب حديثة'),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  cacheExtent: 1000,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final absence = snapshot.data![index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: const Icon(Icons.person_off, color: Colors.orange),
                                        title: Text('غياب ${absence.studentName}'),
                                        subtitle: Text(
                                          'السبب: ${absence.reason}\n'
                                          'التاريخ: ${absence.date.day}/${absence.date.month}/${absence.date.year}',
                                        ),
                                        trailing: Text(
                                          '${absence.createdAt.hour}:${absence.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            // الإشعارات العامة
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _databaseService.getRecentGeneralNotifications(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text('لا توجد إشعارات عامة حديثة'),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  cacheExtent: 1000,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final notification = snapshot.data![index];
                                    final timestamp = notification['timestamp'] != null
                                        ? (notification['timestamp'] as Timestamp).toDate()
                                        : DateTime.now();

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: const Icon(Icons.notifications, color: Colors.blue),
                                        title: Text(notification['title'] ?? 'إشعار'),
                                        subtitle: Text(notification['body'] ?? ''),
                                        trailing: Text(
                                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}


