import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'models/student_model.dart';
import 'firebase_options.dart';

class TestAddStudentScreen extends StatefulWidget {
  const TestAddStudentScreen({super.key});

  @override
  State<TestAddStudentScreen> createState() => _TestAddStudentScreenState();
}

class _TestAddStudentScreenState extends State<TestAddStudentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String _testResult = 'لم يتم الاختبار بعد';
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUser = _authService.currentUser;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار إضافة الطلاب'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة المستخدم:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser != null 
                          ? 'مسجل الدخول: ${_currentUser!.email}'
                          : 'غير مسجل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        color: _currentUser != null ? Colors.green : Colors.red,
                      ),
                    ),
                    if (_currentUser == null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showLoginDialog,
                        child: const Text('تسجيل دخول تجريبي'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Result
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نتيجة الاختبار:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: TextStyle(
                        fontSize: 16,
                        color: _testResult.contains('نجح') ? Colors.green : 
                               _testResult.contains('فشل') ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testAddStudentWithoutPhoto,
              child: _isLoading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('جاري الاختبار...'),
                      ],
                    )
                  : const Text('اختبار إضافة طالب بدون صورة'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testParentChildRelationship,
              child: const Text('اختبار ربط الطالب بولي الأمر'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testGetParentChildren,
              child: const Text('اختبار جلب أطفال ولي الأمر'),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعليمات الاختبار:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. تأكد من تسجيل الدخول أولاً'),
                    Text('2. اختبر إضافة طالب بدون صورة'),
                    Text('3. اختبر ربط الطالب بولي الأمر'),
                    Text('4. اختبر جلب قائمة الأطفال'),
                    SizedBox(height: 8),
                    Text(
                      'ملاحظة: هذا الاختبار يستخدم بيانات تجريبية',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAddStudentWithoutPhoto() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار إضافة طالب...';
    });

    try {
      debugPrint('🧪 Testing add student without photo...');

      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Validate user authentication
      if (_currentUser!.uid.isEmpty) {
        throw Exception('معرف المستخدم غير صالح');
      }

      // Create test student with timestamp to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testStudent = StudentModel(
        id: '', // Will be generated
        name: 'أحمد محمد - اختبار $timestamp',
        parentId: _currentUser!.uid,
        parentName: 'محمد أحمد',
        parentPhone: '0501234567',
        qrCode: '', // Will be generated
        schoolName: 'مدرسة الاختبار',
        grade: 'الصف الثالث',
        busRoute: 'طريق الاختبار',
        photoUrl: null, // No photo for this test
        currentStatus: StudentStatus.home,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Add student with timeout
      final studentId = await _databaseService.addStudent(testStudent).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('انتهت مهلة إضافة الطالب'),
      );

      // Verify student was added
      if (studentId.isEmpty) {
        throw Exception('فشل في الحصول على معرف الطالب');
      }

      setState(() {
        _testResult = '✅ نجح إضافة الطالب بدون صورة\n'
            'معرف الطالب: $studentId\n'
            'الاسم: ${testStudent.name}\n'
            'تم الإنشاء: ${DateTime.now().toString().substring(0, 19)}';
      });

      debugPrint('✅ Test student added successfully: $studentId');

    } catch (e) {
      setState(() {
        _testResult = '❌ فشل إضافة الطالب: ${e.toString()}';
      });

      debugPrint('❌ Test add student failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testParentChildRelationship() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار ربط الطالب بولي الأمر...';
    });

    try {
      debugPrint('🧪 Testing parent-child relationship...');
      
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Create test student for relationship
      final testStudent = StudentModel(
        id: 'test_relationship_${DateTime.now().millisecondsSinceEpoch}',
        name: 'فاطمة علي - اختبار ربط',
        parentId: _currentUser!.uid,
        parentName: 'علي حسن',
        parentPhone: '0507654321',
        qrCode: 'QR_TEST_REL_${DateTime.now().millisecondsSinceEpoch}',
        schoolName: 'مدرسة الربط',
        grade: 'الصف الخامس',
        busRoute: 'طريق الربط',
        photoUrl: null,
        currentStatus: StudentStatus.home,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Test the sync function directly
      await _databaseService.syncStudentWithParent(_currentUser!.uid, testStudent);
      
      setState(() {
        _testResult = '✅ نجح ربط الطالب بولي الأمر\nالطالب: ${testStudent.name}';
      });
      
      debugPrint('✅ Parent-child relationship test successful');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل ربط الطالب بولي الأمر: $e';
      });
      
      debugPrint('❌ Parent-child relationship test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetParentChildren() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار جلب أطفال ولي الأمر...';
    });

    try {
      debugPrint('🧪 Testing get parent children...');
      
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Test getting children from relationships
      final children = await _databaseService.getParentChildrenFromRelationships(_currentUser!.uid);
      
      setState(() {
        _testResult = '✅ نجح جلب أطفال ولي الأمر\nعدد الأطفال: ${children.length}\n'
            '${children.map((child) => '- ${child['name']}').join('\n')}';
      });
      
      debugPrint('✅ Get parent children test successful: ${children.length} children found');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل جلب أطفال ولي الأمر: $e';
      });
      
      debugPrint('❌ Get parent children test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل دخول تجريبي'),
        content: const Text('سيتم تسجيل الدخول بحساب تجريبي للاختبار'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _loginTestUser();
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginTestUser() async {
    try {
      // Try to sign in with test credentials
      await _authService.signInWithEmailAndPassword(
        email: 'test@parent.com',
        password: 'test123456',
      );
      _getCurrentUser();
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تسجيل الدخول: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Function to run the test
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
  runApp(
    MaterialApp(
      title: 'Test Add Student',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const TestAddStudentScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
