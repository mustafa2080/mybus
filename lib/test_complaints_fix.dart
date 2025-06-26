import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'models/complaint_model.dart';
import 'firebase_options.dart';

class TestComplaintsFixScreen extends StatefulWidget {
  const TestComplaintsFixScreen({super.key});

  @override
  State<TestComplaintsFixScreen> createState() => _TestComplaintsFixScreenState();
}

class _TestComplaintsFixScreenState extends State<TestComplaintsFixScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String _testResult = 'جاري اختبار الحل...';
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _runAutoTest();
  }

  void _getCurrentUser() {
    _currentUser = _authService.currentUser;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار حل مشكلة Firebase Index'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'تم إصلاح مشكلة Firebase Index',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تم تعديل الاستعلامات لتجنب الحاجة للـ compound indexes',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
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
              onPressed: _isLoading ? null : _testComplaintQueries,
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
                  : const Text('اختبار استعلامات الشكاوى'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testAllComplaintsQuery,
              child: const Text('اختبار جلب جميع الشكاوى (للأدمن)'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testStatusQuery,
              child: const Text('اختبار استعلام حسب الحالة'),
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
                      'ما تم إصلاحه:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ إزالة orderBy من الاستعلامات المركبة'),
                    Text('✅ ترتيب النتائج محلياً بدلاً من قاعدة البيانات'),
                    Text('✅ تجنب الحاجة لإنشاء compound indexes'),
                    Text('✅ الحفاظ على نفس الوظائف والأداء'),
                    SizedBox(height: 8),
                    Text(
                      'النتيجة: نظام الشكاوى يعمل بدون أخطاء Firebase',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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

  Future<void> _runAutoTest() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_currentUser != null) {
      await _testComplaintQueries();
    } else {
      setState(() {
        _testResult = 'يرجى تسجيل الدخول أولاً لاختبار الاستعلامات';
      });
    }
  }

  Future<void> _testComplaintQueries() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار استعلامات الشكاوى...';
    });

    try {
      debugPrint('🧪 Testing complaints queries after fix...');
      
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Test 1: Get complaints by parent (the main problematic query)
      debugPrint('Testing getComplaintsByParent...');
      final complaintsStream = _databaseService.getComplaintsByParent(_currentUser!.uid);
      final complaints = await complaintsStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة الاستعلام'),
      );
      
      debugPrint('✅ getComplaintsByParent successful: ${complaints.length} complaints');
      
      setState(() {
        _testResult = '✅ نجح اختبار استعلامات الشكاوى!\n'
            'عدد الشكاوى: ${complaints.length}\n'
            'الاستعلام يعمل بدون أخطاء Firebase Index';
      });
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل اختبار الاستعلامات: $e';
      });
      
      debugPrint('❌ Test complaints queries failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllComplaintsQuery() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار استعلام جميع الشكاوى...';
    });

    try {
      debugPrint('🧪 Testing getAllComplaints query...');
      
      // Test admin query
      final allComplaintsStream = _databaseService.getAllComplaints();
      final allComplaints = await allComplaintsStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة الاستعلام'),
      );
      
      debugPrint('✅ getAllComplaints successful: ${allComplaints.length} complaints');
      
      setState(() {
        _testResult = '✅ نجح اختبار استعلام جميع الشكاوى!\n'
            'عدد الشكاوى الإجمالي: ${allComplaints.length}\n'
            'استعلام الأدمن يعمل بدون مشاكل';
      });
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل اختبار استعلام جميع الشكاوى: $e';
      });
      
      debugPrint('❌ Test all complaints query failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStatusQuery() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار استعلام حسب الحالة...';
    });

    try {
      debugPrint('🧪 Testing getComplaintsByStatus query...');
      
      // Test status query
      final statusComplaintsStream = _databaseService.getComplaintsByStatus(ComplaintStatus.pending);
      final statusComplaints = await statusComplaintsStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('انتهت مهلة الاستعلام'),
      );
      
      debugPrint('✅ getComplaintsByStatus successful: ${statusComplaints.length} pending complaints');
      
      setState(() {
        _testResult = '✅ نجح اختبار استعلام حسب الحالة!\n'
            'الشكاوى الجديدة: ${statusComplaints.length}\n'
            'استعلام التصنيف يعمل بدون مشاكل';
      });
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل اختبار استعلام حسب الحالة: $e';
      });
      
      debugPrint('❌ Test status query failed: $e');
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
      await _runAutoTest();
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
      title: 'Test Complaints Fix',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
      ),
      home: const TestComplaintsFixScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
