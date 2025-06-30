import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../models/trip_model.dart';
import '../../models/user_model.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/curved_app_bar.dart';
import '../../widgets/student_avatar.dart';
import '../../models/absence_model.dart';
import 'school_info_screen.dart';
import 'report_absence_screen.dart';
import 'update_student_photo_screen.dart';
import 'add_student_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  List<StudentModel> _students = [];
  int _refreshKey = 0;

  // User and school data
  UserModel? _currentUser;
  Map<String, dynamic> _schoolInfo = {};
  List<BusModel> _allBuses = [];

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
    _loadUserData();
    _loadSchoolData();
  }

  Future<void> _checkProfileCompletion() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final isComplete = await _databaseService.isParentProfileComplete(currentUser.uid);
    if (!isComplete && mounted) {
      // إجبار المستخدم على إكمال البروفايل
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/parent/complete-profile');
      });
    }
  }

  // Load current user data
  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final userData = await _databaseService.getUserData(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromMap(userData);
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Load school information and buses
  Future<void> _loadSchoolData() async {
    try {
      // Load school info
      final schoolDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('school')
          .get();

      if (schoolDoc.exists && mounted) {
        setState(() {
          _schoolInfo = schoolDoc.data() ?? {};
        });
      }

      // Load all buses for emergency contacts
      final buses = await _databaseService.getBusesWithFallback();
      if (mounted) {
        setState(() {
          _allBuses = buses;
        });
      }
    } catch (e) {
      debugPrint('Error loading school data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: EnhancedCurvedAppBar(
        title: 'الرئيسية',
        subtitle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Text('متابعة شاملة لرحلة أطفالك'),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        height: 220,
        leadingIcon: Icons.settings,
        onLeadingPressed: () {
          context.push('/parent/settings');
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 24),
            onPressed: () {
              context.push('/parent/profile');
            },
            tooltip: 'الملف الشخصي',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),
          StreamBuilder<int>(
            stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final notificationCount = snapshot.data ?? 0;
              final hasNotifications = notificationCount > 0;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      hasNotifications ? Icons.notifications_active : Icons.notifications,
                      size: 24,
                      color: hasNotifications ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () {
                      context.push('/parent/notifications');
                    },
                    tooltip: hasNotifications ? '$notificationCount إشعار جديد' : 'الإشعارات',
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
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationCount > 99 ? '99+' : notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 24),
            tooltip: 'المزيد',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'help') {
                context.push('/parent/help');
              } else if (value == 'about') {
                _showAboutDialog(context);
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_center, color: Color(0xFF1E88E5)),
                    SizedBox(width: 12),
                    Text('المساعدة والدعم'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
                    SizedBox(width: 12),
                    Text('حول التطبيق'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<StudentModel>>(
        key: ValueKey(_refreshKey),
        stream: _databaseService.getStudentsByParent(_authService.currentUser?.uid ?? ''),
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
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () => setState(() {}),
                    width: 200,
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data ?? [];
          _students = students; // تحديث قائمة الطلاب

          if (students.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome Card
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                
                // Students List
                ...students.map((student) => _buildStudentCard(student)),
                
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF2C2C2C),
            const Color(0xFF383838),
            const Color(0xFF1E88E5).withOpacity(0.3),
          ] : [
            const Color(0xFF1E88E5),
            const Color(0xFF1976D2),
            const Color(0xFF0D47A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.waving_hand, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser != null ? 'مرحباً بك ${_currentUser!.name}' : 'مرحباً بك',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'تابع رحلة أطفالك بسهولة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
                  builder: (context, snapshot) {
                    final notificationCount = snapshot.data ?? 0;
                    final hasNotifications = notificationCount > 0;

                    return GestureDetector(
                      onTap: () {
                        context.push('/parent/notifications');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasNotifications ? Icons.notifications_active : Icons.notifications,
                              color: hasNotifications ? Colors.yellow : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'الإشعارات',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hasNotifications) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  notificationCount > 99 ? '99+' : notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push('/parent/settings');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الإعدادات',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.feedback,
                  label: 'الشكاوى والاقتراحات',
                  color: const Color(0xFFE53E3E),
                  onTap: () {
                    context.push('/parent/complaints');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.info_outline,
                  label: 'معلومات الباص',
                  color: Colors.teal,
                  onTap: () {
                    _showBusInfoDialog();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.supervisor_account,
                  label: 'معلومات المشرفين',
                  color: const Color(0xFF1E88E5),
                  onTap: () {
                    context.push('/parent/supervisor-info');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // مساحة فارغة للتوازن
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                const Color(0xFF2C2C2C),
                const Color(0xFF383838),
              ] : [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                photoUrl: student.photoUrl,
                studentName: student.name,
                radius: 30,
                onTap: () => _showPhotoOptions(student),
                showCameraIcon: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'الصف: ${student.grade}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(student.currentStatus),
            ],
          ),
          const SizedBox(height: 16),

          // Bus Assignment Info
          _buildBusAssignmentInfo(student),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'عرض السجل',
                  onPressed: () {
                    if (student.id.isNotEmpty) {
                      context.push('/parent/student-activity/${student.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطأ: معرف الطالب غير صحيح'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'معلومات السيارة',
                  onPressed: () {
                    if (student.id.isNotEmpty) {
                      context.push('/parent/bus-info/${student.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطأ: معرف الطالب غير صحيح'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFFFF9800),
                  textColor: Colors.white,
                  height: 40,
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

  Widget _buildStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green;
        icon = Icons.home;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange;
        icon = Icons.directions_bus;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue;
        icon = Icons.school;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusAssignmentInfo(StudentModel student) {
    if (student.busId.isEmpty && student.busRoute.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withAlpha(76)),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تسكين الباص',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'لم يتم تسكين الطالب في باص بعد',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getBusDetails(student.busId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('جاري تحميل معلومات الباص...'),
              ],
            ),
          );
        }

        final busData = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha(76)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'معلومات الباص المُسكن',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (busData != null) ...[
                _buildBusInfoRow('وصف الباص', busData['description'] ?? 'غير محدد'),
                _buildBusInfoRow('خط السير', student.busRoute.isNotEmpty ? student.busRoute : 'غير محدد'),
                // Show supervisor info based on current time and assignment
                FutureBuilder<Map<String, String>>(
                  future: _databaseService.getSupervisorInfoForParent(student.busId),
                  builder: (context, supervisorSnapshot) {
                    final supervisorInfo = supervisorSnapshot.data ?? {};
                    return Column(
                      children: [
                        _buildBusInfoRow('المشرف', supervisorInfo['name'] ?? 'غير محدد'),
                        _buildBusInfoRow(
                          'هاتف المشرف',
                          supervisorInfo['phone'] ?? 'غير محدد',
                          isPhone: supervisorInfo['phone']?.isNotEmpty == true,
                        ),
                        if (supervisorInfo['direction']?.isNotEmpty == true)
                          _buildBusInfoRow('فترة الإشراف', supervisorInfo['direction']!),
                      ],
                    );
                  },
                ),
              ] else ...[
                _buildBusInfoRow('خط السير', student.busRoute.isNotEmpty ? student.busRoute : 'غير محدد'),
                const Text(
                  'تفاصيل الباص غير متاحة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusInfoRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: isPhone
                ? GestureDetector(
                    onTap: () => _makePhoneCall(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getBusDetails(String busId) async {
    if (busId.isEmpty) return null;

    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(busId)
          .get();

      if (busDoc.exists) {
        return busDoc.data();
      }
    } catch (e) {
      debugPrint('Error getting bus details: $e');
    }

    return null;
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_off,
                  label: 'إبلاغ غياب',
                  color: Colors.orange,
                  onTap: () {
                    _showAbsenceDialog();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'إضافة طالب',
                  color: Colors.blue,
                  onTap: () {
                    _navigateToAddStudent();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.access_time,
                  label: 'مواعيد الرحلات',
                  color: Colors.green,
                  onTap: () {
                    _showScheduleDialog();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone,
                  label: 'اتصال طارئ',
                  color: Colors.red,
                  onTap: () {
                    _showEmergencyContactDialog();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.history,
                  label: 'سجل الرحلات',
                  color: Colors.purple,
                  onTap: () {
                    _showTripHistoryDialog();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.poll,
                  label: 'الاستبيانات',
                  color: Colors.indigo,
                  onTap: () {
                    context.push('/parent/surveys');
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFF1E88E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              buttonColor.withOpacity(0.1),
              buttonColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: buttonColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: buttonColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد بيانات طلاب',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم إضافة أي طلاب بعد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'إضافة طالب جديد',
              onPressed: () {
                context.push('/parent/add-student');
              },
              width: 200,
            ),
          ],
        ),
      ),
    );
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

  // دالة لعرض حوار اختيار الطالب لإبلاغ الغياب
  void _showAbsenceDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_students.length == 1) {
      // إذا كان هناك طالب واحد فقط، انتقل مباشرة لشاشة إبلاغ الغياب
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportAbsenceScreen(student: _students.first),
        ),
      );
    } else {
      // إذا كان هناك أكثر من طالب، اعرض حوار الاختيار
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('اختر الطالب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _students.map((student) {
              return ListTile(
                leading: StudentAvatar(
                  photoUrl: student.photoUrl,
                  studentName: student.name,
                  radius: 20,
                  backgroundColor: Colors.blue.withAlpha(25),
                  textColor: Colors.blue,
                ),
                title: Text(student.name),
                subtitle: Text('الصف: ${student.grade} - الخط: ${student.busRoute}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportAbsenceScreen(student: student),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    }
  }

  // دالة لعرض تاريخ الغيابات
  void _showAbsenceHistory() {
    // عرض جميع طلبات الغياب لولي الأمر
    _showParentAbsenceHistory();
  }

  // دالة لعرض جميع طلبات الغياب لولي الأمر
  void _showParentAbsenceHistory() {
    final parentId = _authService.currentUser?.uid;
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في تحديد هوية ولي الأمر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تاريخ طلبات الغياب',
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
                child: StreamBuilder<List<AbsenceModel>>(
                  stream: _databaseService.getAbsencesByParent(parentId),
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
                            Text('خطأ في تحميل البيانات: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات غياب',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'لم ترسل أي طلبات غياب بعد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final absences = snapshot.data!;
                    return ListView.builder(
                      itemCount: absences.length,
                      itemBuilder: (context, index) {
                        final absence = absences[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(absence.status).withAlpha(25),
                              child: Icon(
                                _getStatusIcon(absence.status),
                                color: _getStatusColor(absence.status),
                              ),
                            ),
                            title: Text('${absence.studentName} - ${absence.typeDisplayText}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('التاريخ: ${_formatDate(absence.date)}'),
                                if (absence.isMultipleDays)
                                  Text('إلى: ${_formatDate(absence.endDate!)}'),
                                Text('السبب: ${absence.reason}'),
                                if (absence.notes != null)
                                  Text('ملاحظات: ${absence.notes}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(absence.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                absence.statusDisplayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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



  // دوال مساعدة لعرض تاريخ الغيابات
  Color _getStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Icons.schedule;
      case AbsenceStatus.approved:
        return Icons.check_circle;
      case AbsenceStatus.rejected:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPhotoOptions(StudentModel student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            StudentAvatar(
              photoUrl: student.photoUrl,
              studentName: student.name,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الصف: ${student.grade}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'تحديث صورة الطالب',
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateStudentPhotoScreen(student: student),
                  ),
                );

                // Refresh the page if photo was updated
                if (result == true) {
                  debugPrint('🔄 Photo update confirmed, refreshing UI...');

                  // Force rebuild to refresh the StreamBuilder
                  setState(() {
                    _refreshKey++;
                  });

                  // Wait a moment then refresh again to ensure data is loaded
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        _refreshKey++;
                      });
                    }
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الصورة بنجاح'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icons.camera_alt,
              backgroundColor: const Color(0xFF1E88E5),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'إلغاء',
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
            SizedBox(width: 12),
            Text('حول التطبيق'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'باصي كيدز',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            SizedBox(height: 8),
            Text('تطبيق متابعة النقل المدرسي الآمن'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('الإصدار: 1.0.0'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 16),
                SizedBox(width: 6),
                Text('حماية متقدمة للبيانات'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.support_agent, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text('دعم فني 24/7'),
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

  // دوال الميزات الجديدة المفيدة


  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.green),
            SizedBox(width: 12),
            Text('مواعيد الرحلات'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رحلة الذهاب:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('6:30 ص - وقت الانطلاق'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('7:00 ص - الوصول للمدرسة'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'رحلة العودة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('2:00 م - وقت الانطلاق'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.home, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('2:30 م - الوصول للمنزل'),
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

  Future<Map<String, String>> _getSupervisorInfo() async {
    try {
      // Get current user's students
      final currentUser = _authService.currentUser;
      if (currentUser == null) return {};

      // Get student's bus assignment
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) return {};

      final studentData = studentsSnapshot.docs.first.data();
      final busId = studentData['busId'] as String?;

      if (busId == null || busId.isEmpty) return {};

      // Get supervisor info using the new system
      return await _databaseService.getSupervisorInfoForParent(busId);
    } catch (e) {
      debugPrint('Error getting supervisor info: $e');
      return {
        'name': 'خطأ في التحميل',
        'phone': '',
        'direction': '',
      };
    }
  }

  void _showEmergencyContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.red),
            SizedBox(width: 12),
            Text('اتصال طارئ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emergency, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'أرقام الطوارئ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Emergency numbers
              const Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('الإسعاف: 997'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.local_police, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('الشرطة: 999'),
                ],
              ),
              const SizedBox(height: 16),

              // School contact
              if (_schoolInfo.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'معلومات المدرسة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${_schoolInfo['name'] ?? 'المدرسة'}: ${_schoolInfo['phone'] ?? 'غير متوفر'}'),
                    ),
                  ],
                ),
                if (_schoolInfo['email'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_schoolInfo['email'])),
                    ],
                  ),
                ],
              ],

              // Supervisor contacts
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'معلومات المشرفة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Supervisor info - will be loaded from database
              FutureBuilder<Map<String, String>>(
                future: _getSupervisorInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final supervisorInfo = snapshot.data ?? {};

                  if (supervisorInfo.isEmpty) {
                    return const Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey, size: 20),
                        SizedBox(width: 12),
                        Text('لم يتم تعيين مشرفة للباص بعد'),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Supervisor name and phone
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المشرفة: ${supervisorInfo['name'] ?? 'غير محدد'}'),
                                if (supervisorInfo['phone'] != null && supervisorInfo['phone']!.isNotEmpty)
                                  Text(
                                    supervisorInfo['phone']!,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (supervisorInfo['phone'] != null && supervisorInfo['phone']!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () => _makePhoneCall(supervisorInfo['phone']!),
                            ),
                        ],
                      ),

                      // Trip type info
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Text('متاحة للذهاب والعودة'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يتم الاتصال بالمدرسة...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('اتصال بالمدرسة'),
          ),
        ],
      ),
    );
  }

  void _showTripHistoryDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين لعرض سجل الرحلات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.purple),
            SizedBox(width: 12),
            Text('سجل الرحلات'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where('studentId', whereIn: _students.map((s) => s.id).toList())
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد سجل رحلات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final trips = snapshot.data!.docs;

              return ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final tripData = trips[index].data() as Map<String, dynamic>;
                  final trip = TripModel.fromMap(tripData);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTripActionColor(trip.action),
                        child: Icon(
                          _getTripActionIcon(trip.action),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(trip.studentName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.actionDisplayText),
                          Text(
                            '${trip.formattedDate} - ${trip.formattedTime}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        trip.busRoute,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/parent/trip-history');
            },
            child: const Text('عرض التفاصيل'),
          ),
        ],
      ),
    );
  }

  // Navigate to add student screen
  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStudentScreen(),
      ),
    ).then((_) {
      // Refresh the students list after adding a new student
      setState(() {
        _refreshKey++;
      });
    });
  }

  // Show students status dialog
  void _showStudentsStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 8),
            Text('حالة الطلاب الحالية'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _students.isEmpty
              ? const Text('لا يوجد طلاب مسجلين')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _students.map((student) {
                    return ListTile(
                      leading: StudentAvatar(
                        photoUrl: student.photoUrl,
                        studentName: student.name,
                        radius: 20,
                      ),
                      title: Text(student.name),
                      subtitle: Text('الصف: ${student.grade}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStudentStatusColor(student.currentStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student.statusDisplayText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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

  // Get student status color
  Color _getStudentStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.green;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.blue;
    }
  }

  // Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن الاتصال بالرقم: $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get trip action color
  Color _getTripActionColor(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
      case TripAction.boardBus:
        return Colors.blue;
      case TripAction.arriveAtSchool:
        return Colors.green;
      case TripAction.boardBusToHome:
        return Colors.orange;
      case TripAction.arriveAtHome:
      case TripAction.leaveBus:
        return Colors.purple;
    }
  }

  // Get trip action icon
  IconData _getTripActionIcon(TripAction action) {
    switch (action) {
      case TripAction.boardBusToSchool:
      case TripAction.boardBus:
        return Icons.directions_bus;
      case TripAction.arriveAtSchool:
        return Icons.school;
      case TripAction.boardBusToHome:
        return Icons.home;
      case TripAction.arriveAtHome:
      case TripAction.leaveBus:
        return Icons.home_filled;
    }
  }



  void _showBusInfoDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final student = _students.first;
    if (student.busId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تعيين باص للطالب بعد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.push('/parent/bus-info/${student.id}');
  }
}


