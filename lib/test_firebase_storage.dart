import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class TestFirebaseStorageScreen extends StatefulWidget {
  const TestFirebaseStorageScreen({super.key});

  @override
  State<TestFirebaseStorageScreen> createState() => _TestFirebaseStorageScreenState();
}

class _TestFirebaseStorageScreenState extends State<TestFirebaseStorageScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String _testResult = 'لم يتم الاختبار بعد';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار Firebase Storage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testStorageConnection,
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
                  : const Text('اختبار الاتصال بـ Firebase Storage'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testImageUpload,
              child: const Text('اختبار رفع صورة تجريبية'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _checkStorageRules,
              child: const Text('فحص قواعد التخزين'),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات Firebase:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Project ID: mybus-5a992'),
                    Text('Storage Bucket: mybus-5a992.firebasestorage.app'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testStorageConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار الاتصال...';
    });

    try {
      debugPrint('🔍 Testing Firebase Storage connection...');
      
      // Test basic connection
      final ref = _storage.ref();
      await ref.listAll();
      
      setState(() {
        _testResult = '✅ نجح الاتصال بـ Firebase Storage';
      });
      
      debugPrint('✅ Firebase Storage connection successful');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل الاتصال بـ Firebase Storage: $e';
      });
      
      debugPrint('❌ Firebase Storage connection failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testImageUpload() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار رفع الصورة...';
    });

    try {
      debugPrint('📸 Testing image upload...');
      
      // Create a simple test image (1x1 pixel red image)
      final Uint8List testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
        0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
        0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
        0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x80, 0x00,
        0xFF, 0xD9
      ]);
      
      final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('test_images/$fileName');
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'test_image',
        },
      );

      // Upload
      final uploadTask = ref.putData(testImageData, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _testResult = '✅ نجح رفع الصورة التجريبية\nURL: $downloadUrl';
      });
      
      debugPrint('✅ Test image uploaded successfully: $downloadUrl');
      
      // Clean up - delete the test image
      try {
        await ref.delete();
        debugPrint('🗑️ Test image deleted successfully');
      } catch (deleteError) {
        debugPrint('⚠️ Could not delete test image: $deleteError');
      }
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل رفع الصورة التجريبية: $e';
      });
      
      debugPrint('❌ Test image upload failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkStorageRules() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري فحص قواعد التخزين...';
    });

    try {
      debugPrint('🔍 Checking storage rules...');
      
      // Try to access different paths to check permissions
      final paths = [
        'student_photos/',
        'bus_photos/',
        'profile_photos/',
        'test_images/',
      ];
      
      final results = <String>[];
      
      for (final path in paths) {
        try {
          final ref = _storage.ref().child(path);
          await ref.listAll();
          results.add('✅ $path: يمكن الوصول');
        } catch (e) {
          results.add('❌ $path: لا يمكن الوصول ($e)');
        }
      }
      
      setState(() {
        _testResult = 'نتائج فحص المجلدات:\n${results.join('\n')}';
      });
      
    } catch (e) {
      setState(() {
        _testResult = '❌ فشل فحص قواعد التخزين: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      title: 'Firebase Storage Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const TestFirebaseStorageScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
