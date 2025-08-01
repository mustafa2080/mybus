import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kidsbus/services/enhanced_notification_service.dart';
import 'package:kidsbus/services/notification_service.dart';
import 'package:kidsbus/services/fcm_service.dart';
import 'package:kidsbus/services/fcm_http_service.dart';
import 'package:kidsbus/utils/permissions_helper.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();
  final FCMHttpService _fcmHttpService = FCMHttpService();
  bool _permissionsGranted = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _getFCMToken();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionsHelper.isNotificationPermissionGranted();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  Future<void> _getFCMToken() async {
    final token = _fcmService.currentToken;
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionsHelper.requestNotificationPermission();
    setState(() {
      _permissionsGranted = granted;
    });
    
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى السماح بالإشعارات من إعدادات التطبيق'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      await _enhancedService.sendNotificationToUser(
        userId: 'test_user',
        title: 'اختبار الإشعار المحلي',
        body: 'هذا إشعار اختبار مع صوت واهتزاز',
        type: 'general',
      );
      
      _showSuccessMessage('تم إرسال الإشعار المحلي بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    }
  }

  Future<void> _testStudentNotification() async {
    try {
      await _enhancedService.notifyStudentAssignment(
        studentId: 'test_student',
        studentName: 'أحمد محمد',
        busId: 'bus_001',
        busRoute: 'الطريق الأول',
        parentId: 'test_parent',
        supervisorId: 'test_supervisor',
        parentName: 'محمد أحمد',
        parentPhone: '01234567890',
      );

      _showSuccessMessage('تم إرسال إشعار الطالب بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الطالب: $e');
    }
  }

  Future<void> _testBusNotification() async {
    try {
      await _notificationService.notifyStudentBoardedWithSound(
        studentId: 'test_student',
        studentName: 'فاطمة أحمد',
        busId: 'bus_002',
        parentId: 'test_parent',
        supervisorId: 'test_supervisor',
      );

      _showSuccessMessage('تم إرسال إشعار الباص بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الباص: $e');
    }
  }

  Future<void> _testEmergencyNotification() async {
    try {
      await _enhancedService.notifyEmergency(
        busId: 'bus_003',
        supervisorId: 'test_supervisor',
        supervisorName: 'محمد علي',
        emergencyType: 'طوارئ طبية',
        description: 'حالة طوارئ طبية في الباص',
        parentIds: ['test_parent'],
      );

      _showSuccessMessage('تم إرسال إشعار الطوارئ بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الطوارئ: $e');
    }
  }

  Future<void> _testStudentDataUpdateNotification() async {
    try {
      await _enhancedService.notifyStudentDataUpdate(
        studentId: 'test_student',
        studentName: 'سارة أحمد',
        parentId: 'test_parent',
        busId: 'bus_001',
        updatedFields: {
          'name': {'old': 'سارة محمد', 'new': 'سارة أحمد'},
          'grade': {'old': 'الصف الثاني', 'new': 'الصف الثالث'},
          'busId': {'old': 'غير محدد', 'new': 'باص رقم 123'},
        },
        adminName: 'أحمد الإدمن',
      );

      _showSuccessMessage('تم إرسال إشعار تحديث البيانات بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار تحديث البيانات: $e');
    }
  }

  Future<void> _testFCMStatus() async {
    try {
      final isInitialized = _fcmService.isInitialized;
      final token = _fcmService.currentToken;

      if (isInitialized && token != null) {
        _showSuccessMessage('FCM جاهز ومتصل\nToken: ${token.substring(0, 20)}...');
      } else {
        _showErrorMessage('FCM غير جاهز أو لا يوجد Token');
      }
    } catch (e) {
      _showErrorMessage('خطأ في فحص حالة FCM: $e');
    }
  }

  Future<void> _testBackgroundNotification() async {
    try {
      await _fcmService.sendTestNotification();
      _showSuccessMessage('تم إرسال إشعار تجريبي\nتحقق من شريط الإشعارات');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار التجريبي: $e');
    }
  }

  Future<void> _testNewParentRegistration() async {
    try {
      await _enhancedService.notifyNewParentRegistration(
        parentId: 'test_parent_123',
        parentName: 'أحمد محمد علي',
        parentEmail: 'ahmed@example.com',
        parentPhone: '01234567890',
        registrationDate: DateTime.now(),
      );
      _showSuccessMessage('تم إرسال إشعار تسجيل ولي أمر جديد');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار تسجيل ولي الأمر: $e');
    }
  }

  Future<void> _testNewSurvey() async {
    try {
      await _enhancedService.notifyNewSurvey(
        surveyId: 'survey_123',
        surveyTitle: 'استبيان رضا أولياء الأمور',
        surveyDescription: 'نود معرفة رأيكم في خدمة النقل المدرسي',
        createdBy: 'الإدارة',
        deadline: DateTime.now().add(const Duration(days: 7)),
        targetUserIds: ['test_parent_123', 'test_parent_456'],
      );
      _showSuccessMessage('تم إرسال إشعار استبيان جديد');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الاستبيان: $e');
    }
  }

  Future<void> _testSupervisorAssignment() async {
    try {
      await _enhancedService.notifyNewSupervisorAssignment(
        supervisorId: 'supervisor_123',
        supervisorName: 'محمد أحمد',
        busId: 'bus_001',
        busRoute: 'الرياض - حي النرجس',
        assignedBy: 'مدير النقل',
      );
      _showSuccessMessage('تم إرسال إشعار تعيين مشرف جديد');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار تعيين المشرف: $e');
    }
  }

  Future<void> _testCurrentUserNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorMessage('يجب تسجيل الدخول أولاً');
        return;
      }

      // إرسال إشعار للمستخدم الحالي فقط
      await _enhancedService.sendNotificationToUser(
        userId: currentUser.uid,
        title: '🔔 إشعار للمستخدم الحالي فقط',
        body: 'هذا الإشعار يجب أن يظهر للمستخدم الحالي فقط وليس لجميع المستخدمين',
        type: 'admin',
        data: {
          'testType': 'current_user_only',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _showSuccessMessage('تم إرسال إشعار للمستخدم الحالي فقط\nUser ID: ${currentUser.uid}');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    }
  }

  Future<void> _testRealFCMNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorMessage('يجب تسجيل الدخول أولاً');
        return;
      }

      // التحقق من إعدادات FCM أولاً
      final isValid = await _enhancedService.validateFCMSetup();
      if (!isValid) {
        _showErrorMessage('إعدادات FCM غير صحيحة\nتأكد من تسجيل الدخول وحفظ FCM token');
        return;
      }

      // إرسال إشعار اختبار حقيقي
      final success = await _enhancedService.sendTestFCMNotification();

      if (success) {
        _showSuccessMessage('تم إرسال إشعار FCM حقيقي!\nيجب أن يظهر في شريط الإشعارات حتى لو كان التطبيق في الخلفية');
      } else {
        _showErrorMessage('فشل في إرسال إشعار FCM\nتحقق من الإعدادات والاتصال');
      }
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار FCM: $e');
    }
  }

  Future<void> _testInstantNotification() async {
    try {
      // إرسال إشعار فوري بدون أي شروط
      final success = await _fcmHttpService.sendInstantTestNotification(
        title: '🔔 إشعار فوري للاختبار',
        body: 'هذا إشعار فوري يجب أن يظهر في شريط الإشعارات الآن!\nحتى لو كان التطبيق في الخلفية أو مغلق',
        channelId: 'mybus_notifications',
        data: {
          'type': 'instant_test',
          'timestamp': DateTime.now().toIso8601String(),
          'action': 'instant_notification_test',
        },
      );

      if (success) {
        _showSuccessMessage('تم إرسال إشعار فوري!\nيجب أن تراه في شريط الإشعارات الآن');
      } else {
        _showErrorMessage('فشل في إرسال الإشعار الفوري');
      }
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار الفوري: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الإشعارات'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // حالة الأذونات
            Card(
              color: _permissionsGranted ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _permissionsGranted ? Icons.check_circle : Icons.error,
                      color: _permissionsGranted ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _permissionsGranted ? 'أذونات الإشعارات مفعلة' : 'أذونات الإشعارات غير مفعلة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _permissionsGranted ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!_permissionsGranted) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _requestPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('طلب الأذونات'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // حالة FCM
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_sync,
                      color: Colors.blue,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'حالة Firebase Cloud Messaging',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fcmToken != null
                        ? 'متصل - Token: ${_fcmToken!.substring(0, 20)}...'
                        : 'غير متصل',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _testFCMStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('فحص حالة FCM'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // أزرار الاختبار
            const Text(
              'اختبارات الإشعارات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            _buildTestButton(
              'اختبار الإشعار العام',
              'إشعار عام مع صوت واهتزاز',
              Icons.notifications,
              Colors.blue,
              _testLocalNotification,
            ),
            
            _buildTestButton(
              'اختبار إشعار الطالب',
              'إشعار تسكين طالب في الباص',
              Icons.person,
              Colors.green,
              _testStudentNotification,
            ),
            
            _buildTestButton(
              'اختبار إشعار الباص',
              'إشعار ركوب/نزول الطالب',
              Icons.directions_bus,
              Colors.orange,
              _testBusNotification,
            ),
            
            _buildTestButton(
              'اختبار إشعار الطوارئ',
              'إشعار طوارئ عاجل',
              Icons.emergency,
              Colors.red,
              _testEmergencyNotification,
            ),

            _buildTestButton(
              'اختبار تحديث بيانات الطالب',
              'إشعار تحديث بيانات من الإدمن',
              Icons.edit_note,
              Colors.purple,
              _testStudentDataUpdateNotification,
            ),

            _buildTestButton(
              'اختبار إشعار الخلفية',
              'اختبار ظهور الإشعار في شريط الإشعارات',
              Icons.notifications_active,
              Colors.teal,
              _testBackgroundNotification,
            ),

            const SizedBox(height: 16),
            const Text(
              'إشعارات الإدمن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              'اختبار تسجيل ولي أمر جديد',
              'إشعار للإدمن عند تسجيل ولي أمر جديد',
              Icons.person_add,
              Colors.green,
              _testNewParentRegistration,
            ),

            _buildTestButton(
              'اختبار استبيان جديد',
              'إشعار للمستخدمين عند إنشاء استبيان جديد',
              Icons.poll,
              Colors.indigo,
              _testNewSurvey,
            ),

            const SizedBox(height: 16),
            const Text(
              'إشعارات المشرف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              'اختبار تعيين مشرف جديد',
              'إشعار للمشرف عند تعيينه لباص جديد',
              Icons.assignment_ind,
              Colors.deepOrange,
              _testSupervisorAssignment,
            ),

            const SizedBox(height: 16),
            const Text(
              'اختبار الإشعارات المحددة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            _buildTestButton(
              'اختبار إشعار للمستخدم الحالي فقط',
              'إشعار يظهر للمستخدم الحالي فقط وليس للجميع',
              Icons.person,
              Colors.red,
              _testCurrentUserNotification,
            ),

            _buildTestButton(
              'اختبار إشعار FCM حقيقي',
              'إشعار FCM حقيقي يظهر في الخلفية',
              Icons.cloud_upload,
              Colors.purple,
              _testRealFCMNotification,
            ),

            _buildTestButton(
              'اختبار إشعار فوري',
              'إشعار فوري يظهر في شريط الإشعارات الآن',
              Icons.flash_on,
              Colors.orange,
              _testInstantNotification,
            ),
            
            const SizedBox(height: 20),
            
            // ملاحظات
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات مهمة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• تأكد من تفعيل الإشعارات في إعدادات الهاتف'),
                    Text('• تأكد من عدم تفعيل الوضع الصامت'),
                    Text('• قد تحتاج لإعادة تشغيل التطبيق بعد تفعيل الأذونات'),
                    Text('• الإشعارات ستظهر في شريط الإشعارات حتى لو كان التطبيق مغلق'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: _permissionsGranted ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
