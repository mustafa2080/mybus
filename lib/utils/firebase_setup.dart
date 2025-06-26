import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class FirebaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseService _databaseService = DatabaseService();
  static final StorageService _storageService = StorageService();

  // إعداد البيانات الأولية فقط إذا لم تكن موجودة
  static Future<void> setupInitialDataIfNeeded() async {
    try {
      // فحص سريع لوجود البيانات
      final hasData = await _checkIfDataExists();
      if (hasData) {
        print('✅ البيانات الأولية موجودة بالفعل');
        return;
      }

      print('🚀 بدء إعداد البيانات الأولية...');

      // إنشاء البيانات بشكل متوازي لتوفير الوقت
      await Future.wait([
        _createDefaultAdmin(),
        _createDefaultSupervisor(),
        _createDefaultParent(),
      ]);

      // إنشاء طلاب تجريبيين
      await _createSampleStudents();

      // إعداد Firebase Storage في الخلفية
      setupFirebaseStorage(); // بدون await

      print('✅ تم إعداد البيانات الأولية بنجاح!');
    } catch (e) {
      print('❌ خطأ في إعداد البيانات الأولية: $e');
    }
  }

  // فحص سريع لوجود البيانات
  static Future<bool> _checkIfDataExists() async {
    try {
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@mybus.com')
          .limit(1)
          .get();

      return adminQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // إعداد البيانات الأولية (النسخة الأصلية للاستخدام اليدوي)
  static Future<void> setupInitialData() async {
    try {
      print('🚀 بدء إعداد البيانات الأولية...');

      // إنشاء مستخدم أدمن افتراضي
      await _createDefaultAdmin();

      // إنشاء مستخدم مشرف افتراضي
      await _createDefaultSupervisor();

      // إنشاء مستخدم ولي أمر افتراضي
      await _createDefaultParent();

      // إنشاء طلاب تجريبيين
      await _createSampleStudents();

      // إعداد Firebase Storage
      await setupFirebaseStorage();

      print('✅ تم إعداد البيانات الأولية بنجاح!');
    } catch (e) {
      print('❌ خطأ في إعداد البيانات الأولية: $e');
    }
  }

  // إنشاء مستخدم أدمن افتراضي
  static Future<void> _createDefaultAdmin() async {
    try {
      const adminEmail = 'admin@mybus.com';
      const adminPassword = 'admin123456';
      
      // التحقق من وجود الأدمن
      final existingAdmin = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .get();
      
      if (existingAdmin.docs.isNotEmpty) {
        print('👤 الأدمن موجود بالفعل');
        return;
      }

      // إنشاء حساب الأدمن
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (userCredential.user != null) {
        final admin = UserModel(
          id: userCredential.user!.uid,
          email: adminEmail,
          name: 'مدير النظام',
          phone: '0501234567',
          userType: UserType.admin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(admin.toMap());

        print('👤 تم إنشاء حساب الأدمن: $adminEmail');
      }
    } catch (e) {
      print('❌ خطأ في إنشاء الأدمن: $e');
    }
  }

  // إنشاء مستخدم مشرف افتراضي
  static Future<void> _createDefaultSupervisor() async {
    try {
      const supervisorEmail = 'supervisor@mybus.com';
      const supervisorPassword = 'supervisor123456';
      
      // التحقق من وجود المشرف
      final existingSupervisor = await _firestore
          .collection('users')
          .where('email', isEqualTo: supervisorEmail)
          .get();
      
      if (existingSupervisor.docs.isNotEmpty) {
        print('👨‍🏫 المشرف موجود بالفعل');
        return;
      }

      // إنشاء حساب المشرف
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: supervisorEmail,
        password: supervisorPassword,
      );

      if (userCredential.user != null) {
        final supervisor = UserModel(
          id: userCredential.user!.uid,
          email: supervisorEmail,
          name: 'أحمد المشرف',
          phone: '0507654321',
          userType: UserType.supervisor,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(supervisor.toMap());

        print('👨‍🏫 تم إنشاء حساب المشرف: $supervisorEmail');
      }
    } catch (e) {
      print('❌ خطأ في إنشاء المشرف: $e');
    }
  }

  // إنشاء مستخدم ولي أمر افتراضي
  static Future<void> _createDefaultParent() async {
    try {
      const parentEmail = 'parent@mybus.com';
      const parentPassword = 'parent123456';

      // التحقق من وجود ولي الأمر
      final existingParent = await _firestore
          .collection('users')
          .where('email', isEqualTo: parentEmail)
          .get();

      if (existingParent.docs.isNotEmpty) {
        print('👨‍👩‍👧‍👦 ولي الأمر موجود بالفعل');
        return;
      }

      // إنشاء حساب ولي الأمر
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: parentEmail,
        password: parentPassword,
      );

      if (userCredential.user != null) {
        final parent = UserModel(
          id: userCredential.user!.uid,
          email: parentEmail,
          name: 'أحمد محمد',
          phone: '0501111111',
          userType: UserType.parent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(parent.toMap());

        print('👨‍👩‍👧‍👦 تم إنشاء حساب ولي الأمر: $parentEmail');
      }
    } catch (e) {
      print('❌ خطأ في إنشاء ولي الأمر: $e');
    }
  }

  // إنشاء طلاب تجريبيين
  static Future<void> _createSampleStudents() async {
    try {
      // التحقق من وجود طلاب
      final existingStudents = await _firestore.collection('students').get();
      
      if (existingStudents.docs.isNotEmpty) {
        print('👨‍🎓 الطلاب موجودون بالفعل');
        return;
      }

      final sampleStudents = [
        {
          'name': 'محمد أحمد',
          'parentName': 'أحمد محمد',
          'parentPhone': '0501111111',
          'grade': 'الصف الأول',
          'schoolName': 'مدرسة النور الابتدائية',
          'busRoute': 'الخط الأول',
        },
        {
          'name': 'فاطمة علي',
          'parentName': 'علي حسن',
          'parentPhone': '0502222222',
          'grade': 'الصف الثاني',
          'schoolName': 'مدرسة النور الابتدائية',
          'busRoute': 'الخط الأول',
        },
        {
          'name': 'عبدالله سالم',
          'parentName': 'سالم عبدالله',
          'parentPhone': '0503333333',
          'grade': 'الصف الثالث',
          'schoolName': 'مدرسة النور الابتدائية',
          'busRoute': 'الخط الثاني',
        },
        {
          'name': 'نورا خالد',
          'parentName': 'خالد نور',
          'parentPhone': '0504444444',
          'grade': 'الصف الرابع',
          'schoolName': 'مدرسة النور الابتدائية',
          'busRoute': 'الخط الثاني',
        },
        {
          'name': 'يوسف إبراهيم',
          'parentName': 'إبراهيم يوسف',
          'parentPhone': '0505555555',
          'grade': 'الصف الخامس',
          'schoolName': 'مدرسة النور الابتدائية',
          'busRoute': 'الخط الثالث',
        },
      ];

      // الحصول على UID ولي الأمر الافتراضي
      final parentQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'parent@mybus.com')
          .get();

      String parentId = '';
      if (parentQuery.docs.isNotEmpty) {
        parentId = parentQuery.docs.first.id;
      }

      for (final studentData in sampleStudents) {
        final studentId = _databaseService.generateTripId();
        final qrCode = await _databaseService.generateQRCode();

        final student = StudentModel(
          id: studentId,
          name: studentData['name']!,
          parentId: parentId, // ربط الطالب بولي الأمر
          parentName: studentData['parentName']!,
          parentPhone: studentData['parentPhone']!,
          qrCode: qrCode,
          schoolName: studentData['schoolName']!,
          grade: studentData['grade']!,
          busRoute: studentData['busRoute']!,
          currentStatus: StudentStatus.home,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.addStudent(student);
        print('👨‍🎓 تم إنشاء الطالب: ${student.name}');
      }

      print('✅ تم إنشاء ${sampleStudents.length} طلاب تجريبيين');
    } catch (e) {
      print('❌ خطأ في إنشاء الطلاب التجريبيين: $e');
    }
  }

  // التحقق من إعداد Firebase (نسخة سريعة)
  static Future<bool> checkFirebaseSetup() async {
    try {
      // فحص سريع بدون كتابة بيانات
      await _firestore.collection('users').limit(1).get();

      print('✅ Firebase متصل بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال بـ Firebase: $e');
      return false;
    }
  }

  // فحص شامل لـ Firebase (للاستخدام عند الحاجة)
  static Future<bool> checkFirebaseSetupDetailed() async {
    try {
      // التحقق من الاتصال بـ Firestore
      await _firestore.collection('test').doc('test').set({'test': true});
      await _firestore.collection('test').doc('test').delete();

      print('✅ Firebase متصل بنجاح (فحص شامل)');
      return true;
    } catch (e) {
      print('❌ خطأ في الاتصال بـ Firebase: $e');
      return false;
    }
  }

  // إعداد Firebase Storage
  static Future<void> setupFirebaseStorage() async {
    try {
      print('📁 إعداد Firebase Storage...');

      // فحص حالة Storage
      final status = await _storageService.checkStorageStatus();
      print('📊 حالة Storage: $status');

      if (!status['isEnabled']) {
        print('⚠️ Firebase Storage غير مفعل. يرجى تفعيله من Firebase Console');
        return;
      }

      if (!status['canWrite']) {
        print('⚠️ لا توجد صلاحيات كتابة في Storage. يرجى مراجعة قواعد الأمان');
        return;
      }

      // إنشاء المجلدات الأساسية
      final initialized = await _storageService.initializeStorage();
      if (initialized) {
        print('✅ تم إعداد Firebase Storage بنجاح');
      } else {
        print('⚠️ فشل في إعداد Firebase Storage');
      }

    } catch (e) {
      print('❌ خطأ في إعداد Firebase Storage: $e');
    }
  }

  // إعداد فهارس Firestore
  static Future<void> setupFirestoreIndexes() async {
    try {
      print('📊 إعداد فهارس Firestore...');

      // إعداد counter للباركود
      await _firestore
          .collection('counters')
          .doc('student_qr_code')
          .set({'value': 999}, SetOptions(merge: true));

      print('📊 تم إعداد counter الباركود');

      // هذه الفهارس سيتم إنشاؤها تلقائياً عند أول استعلام
      // أو يمكن إنشاؤها يدوياً من Firebase Console

      print('📊 تم إعداد فهارس Firestore');
    } catch (e) {
      print('❌ خطأ في إعداد فهارس Firestore: $e');
    }
  }

  // تنظيف البيانات التجريبية
  static Future<void> cleanupTestData() async {
    try {
      print('🧹 تنظيف البيانات التجريبية...');
      
      // حذف المجموعة التجريبية
      final testDocs = await _firestore.collection('test').get();
      for (final doc in testDocs.docs) {
        await doc.reference.delete();
      }
      
      print('🧹 تم تنظيف البيانات التجريبية');
    } catch (e) {
      print('❌ خطأ في تنظيف البيانات: $e');
    }
  }

  // إعادة تعيين كلمة مرور الأدمن
  static Future<void> resetAdminPassword() async {
    try {
      const adminEmail = 'admin@mybus.com';
      await _auth.sendPasswordResetEmail(email: adminEmail);
      print('📧 تم إرسال رابط إعادة تعيين كلمة المرور للأدمن');
    } catch (e) {
      print('❌ خطأ في إرسال رابط إعادة تعيين كلمة المرور: $e');
    }
  }

  // طباعة معلومات الإعداد
  static void printSetupInfo() {
    print('''
🚀 معلومات إعداد Firebase:

📧 حساب الأدمن:
   البريد الإلكتروني: admin@mybus.com
   كلمة المرور: admin123456

👨‍🏫 حساب المشرف:
   البريد الإلكتروني: supervisor@mybus.com
   كلمة المرور: supervisor123456

👨‍👩‍👧‍👦 حساب ولي الأمر:
   البريد الإلكتروني: parent@mybus.com
   كلمة المرور: parent123456

📱 للاختبار:
   1. سجل دخول كأدمن لإدارة النظام
   2. سجل دخول كمشرف لمسح QR Code
   3. أنشئ حساب ولي أمر جديد للاختبار

🔗 روابط مفيدة:
   Firebase Console: https://console.firebase.google.com/
   مشروع Firebase: mybus-5a992
    ''');
  }
}
