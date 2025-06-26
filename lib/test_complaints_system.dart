import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'models/complaint_model.dart';
import 'firebase_options.dart';

class TestComplaintsSystemScreen extends StatefulWidget {
  const TestComplaintsSystemScreen({super.key});

  @override
  State<TestComplaintsSystemScreen> createState() => _TestComplaintsSystemScreenState();
}

class _TestComplaintsSystemScreenState extends State<TestComplaintsSystemScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String _testResult = 'لم يتم الاختبار بعد';
  bool _isLoading = false;
  User? _currentUser;
  List<ComplaintModel> _complaints = [];

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
        title: const Text('اختبار نظام الشكاوى'),
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
              onPressed: _isLoading || _currentUser == null ? null : _testAddComplaint,
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
                  : const Text('اختبار إضافة شكوى'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testGetComplaints,
              child: const Text('اختبار جلب الشكاوى'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testComplaintResponse,
              child: const Text('اختبار رد الإدارة'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading || _currentUser == null ? null : _testComplaintStats,
              child: const Text('اختبار إحصائيات الشكاوى'),
            ),
            
            const SizedBox(height: 20),
            
            // Complaints List
            if (_complaints.isNotEmpty) ...[
              const Text(
                'الشكاوى المضافة:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _complaints[index];
                    return Card(
                      child: ListTile(
                        title: Text(complaint.title),
                        subtitle: Text(complaint.description),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              complaint.statusDisplayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              complaint.priorityDisplayName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
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
                    Text('2. اختبر إضافة شكوى جديدة'),
                    Text('3. اختبر جلب الشكاوى'),
                    Text('4. اختبر رد الإدارة'),
                    Text('5. اختبر الإحصائيات'),
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

  Future<void> _testAddComplaint() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار إضافة شكوى...';
    });

    try {
      debugPrint('🧪 Testing add complaint...');
      
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Create test complaint
      final testComplaint = ComplaintModel(
        id: '', // Will be generated
        parentId: _currentUser!.uid,
        parentName: 'ولي أمر تجريبي',
        parentPhone: '0501234567',
        studentId: null,
        studentName: null,
        title: 'شكوى تجريبية - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'هذه شكوى تجريبية لاختبار النظام. تم إنشاؤها تلقائياً للتأكد من عمل النظام بشكل صحيح.',
        type: ComplaintType.other,
        priority: ComplaintPriority.medium,
        attachments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add complaint
      final complaintId = await _databaseService.addComplaint(testComplaint);
      
      setState(() {
        _testResult = '✅ نجح إضافة الشكوى\nمعرف الشكوى: $complaintId';
      });
      
      debugPrint('✅ Test complaint added successfully: $complaintId');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل إضافة الشكوى: $e';
      });
      
      debugPrint('❌ Test add complaint failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetComplaints() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار جلب الشكاوى...';
    });

    try {
      debugPrint('🧪 Testing get complaints...');
      
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Get complaints for current user
      final complaintsStream = _databaseService.getComplaintsByParent(_currentUser!.uid);
      final complaints = await complaintsStream.first;
      
      setState(() {
        _complaints = complaints;
        _testResult = '✅ نجح جلب الشكاوى\nعدد الشكاوى: ${complaints.length}';
      });
      
      debugPrint('✅ Get complaints test successful: ${complaints.length} complaints found');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل جلب الشكاوى: $e';
      });
      
      debugPrint('❌ Get complaints test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testComplaintResponse() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار رد الإدارة...';
    });

    try {
      debugPrint('🧪 Testing complaint response...');
      
      if (_complaints.isEmpty) {
        throw Exception('لا توجد شكاوى للاختبار عليها');
      }

      final firstComplaint = _complaints.first;
      
      // Add admin response
      await _databaseService.addComplaintResponse(
        firstComplaint.id,
        'رد تجريبي من الإدارة - تم حل المشكلة',
        'admin_test',
      );
      
      setState(() {
        _testResult = '✅ نجح إضافة رد الإدارة\nالشكوى: ${firstComplaint.title}';
      });
      
      debugPrint('✅ Complaint response test successful');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل إضافة رد الإدارة: $e';
      });
      
      debugPrint('❌ Complaint response test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testComplaintStats() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار إحصائيات الشكاوى...';
    });

    try {
      debugPrint('🧪 Testing complaint stats...');
      
      // Get complaint statistics
      final stats = await _databaseService.getComplaintsStats();
      
      setState(() {
        _testResult = '✅ نجح جلب الإحصائيات\n'
            'الإجمالي: ${stats['total'] ?? 0}\n'
            'جديدة: ${stats['pending'] ?? 0}\n'
            'قيد المعالجة: ${stats['inProgress'] ?? 0}\n'
            'محلولة: ${stats['resolved'] ?? 0}\n'
            'عاجلة: ${stats['urgent'] ?? 0}';
      });
      
      debugPrint('✅ Complaint stats test successful: $stats');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل جلب الإحصائيات: $e';
      });
      
      debugPrint('❌ Complaint stats test failed: $e');
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
      title: 'Test Complaints System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const TestComplaintsSystemScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
