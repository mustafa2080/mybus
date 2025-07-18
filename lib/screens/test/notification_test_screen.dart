import 'package:flutter/material.dart';
import 'package:kidsbus/services/enhanced_notification_service.dart';
import 'package:kidsbus/services/notification_service.dart';
import 'package:kidsbus/utils/permissions_helper.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();
  final NotificationService _notificationService = NotificationService();
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionsHelper.isNotificationPermissionGranted();
    setState(() {
      _permissionsGranted = granted;
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
      );
      
      _showSuccessMessage('تم إرسال إشعار الطالب بنجاح');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الطالب: $e');
    }
  }

  Future<void> _testBusNotification() async {
    try {
      await _notificationService.notifyStudentBoardingWithSound(
        studentId: 'test_student',
        studentName: 'فاطمة أحمد',
        busId: 'bus_002',
        parentId: 'test_parent',
        supervisorId: 'test_supervisor',
        action: 'boarding',
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
