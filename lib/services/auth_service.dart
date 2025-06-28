import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 محاولة تسجيل الدخول للمستخدم: $email');

      // محاولة تسجيل الدخول مع معالجة خاصة لخطأ PigeonUserDetails
      UserCredential? result;

      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // إذا كان الخطأ متعلق بـ PigeonUserDetails، نحاول مرة أخرى
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('List<Object?>')) {
          debugPrint('🔄 إعادة محاولة تسجيل الدخول بسبب خطأ PigeonUserDetails...');
          await Future.delayed(const Duration(milliseconds: 500));

          // محاولة ثانية
          result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (result.user != null) {
        debugPrint('✅ تم تسجيل الدخول بنجاح، جلب بيانات المستخدم...');

        // انتظار قصير للتأكد من تحديث حالة المصادقة
        await Future.delayed(const Duration(milliseconds: 300));

        final userData = await getUserData(result.user!.uid);

        if (userData != null) {
          debugPrint('✅ تم جلب بيانات المستخدم: ${userData.name} (${userData.userType})');
        } else {
          debugPrint('⚠️ لم يتم العثور على بيانات المستخدم في Firestore');

          // إذا لم نجد بيانات المستخدم، نحاول إنشاؤها
          if (email == 'admin@mybus.com') {
            debugPrint('🔧 إنشاء بيانات الأدمن المفقودة...');
            final adminUser = UserModel(
              id: result.user!.uid,
              email: email,
              name: 'مدير النظام',
              phone: '0501234567',
              userType: UserType.admin,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .set(adminUser.toMap());

            return adminUser;
          } else if (email == 'supervisor@mybus.com') {
            debugPrint('🔧 إنشاء بيانات المشرف المفقودة...');
            final supervisorUser = UserModel(
              id: result.user!.uid,
              email: email,
              name: 'أحمد المشرف',
              phone: '0507654321',
              userType: UserType.supervisor,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .set(supervisorUser.toMap());

            return supervisorUser;
          }
        }

        return userData;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ خطأ في المصادقة: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ خطأ عام في تسجيل الدخول: $e');

      // إذا كان الخطأ متعلق بـ PigeonUserDetails، نعطي رسالة أوضح
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        throw Exception('خطأ في إعدادات Firebase. يرجى إعادة تشغيل التطبيق.');
      }

      throw Exception('خطأ في تسجيل الدخول: $e');
    }
  }

  // Register new user
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          phone: phone,
          userType: userType,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return UserModel.fromMap(data);
        } else {
          debugPrint('❌ خطأ: بيانات المستخدم ليست من النوع المتوقع: ${data.runtimeType}');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المستخدم: $e');
      throw Exception('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات المستخدم: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('خطأ في تسجيل الخروج: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة أو منتهية الصلاحية';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالشبكة';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      default:
        return 'حدث خطأ في المصادقة: ${e.code} - ${e.message}';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.admin;
  }

  // Check if user is supervisor
  Future<bool> isSupervisor() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.supervisor;
  }

  // Check if user is parent
  Future<bool> isParent() async {
    final user = await getUserData(currentUser?.uid ?? '');
    return user?.userType == UserType.parent;
  }
}
