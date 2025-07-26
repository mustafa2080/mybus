import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/student_model.dart';
import '../models/complaint_model.dart';
import '../models/absence_model.dart';
import '../models/supervisor_evaluation_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

/// خدمة مراقبة الأحداث وتفعيل الإشعارات تلقائياً
class EventTriggerService {
  static final EventTriggerService _instance = EventTriggerService._internal();
  factory EventTriggerService() => _instance;
  EventTriggerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  final List<StreamSubscription> _subscriptions = [];
  bool _isInitialized = false;

  /// تهيئة خدمة مراقبة الأحداث
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔍 بدء تهيئة خدمة مراقبة الأحداث...');

      // تهيئة خدمة الإشعارات
      await _notificationService.initialize();

      // بدء مراقبة الأحداث المختلفة
      _startMonitoringEvents();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة مراقبة الأحداث بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة مراقبة الأحداث: $e');
      rethrow;
    }
  }

  /// بدء مراقبة جميع الأحداث
  void _startMonitoringEvents() {
    // مراقبة الشكاوى الجديدة
    _monitorComplaints();

    // مراقبة الطلاب الجدد
    _monitorNewStudents();

    // مراقبة تقارير الغياب
    _monitorAbsenceReports();

    // مراقبة تقييمات المشرفين
    _monitorSupervisorEvaluations();

    // مراقبة الرحلات (QR Code scanning)
    _monitorTrips();

    // مراقبة المستخدمين الجدد
    _monitorNewUsers();

    // مراقبة تعيينات المشرفين
    _monitorSupervisorAssignments();

    // مراقبة إكمال البروفايل
    _monitorProfileCompletion();

    // مراقبة تعيين الطلاب في خطوط السير
    _monitorStudentBusAssignments();

    // مراقبة حذف الطلاب
    _monitorStudentDeletion();

    // مراقبة تحديث بيانات الطلاب للمشرفين
    _monitorStudentDataUpdatesForSupervisors();

    debugPrint('🔍 تم بدء مراقبة ${_subscriptions.length} نوع من الأحداث');
  }

  /// مراقبة الشكاوى الجديدة
  void _monitorComplaints() {
    final subscription = _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewComplaint(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة شكوى جديدة
  Future<void> _handleNewComplaint(Map<String, dynamic> complaintData) async {
    try {
      final complaint = ComplaintModel.fromMap(complaintData);
      
      debugPrint('📝 شكوى جديدة: ${complaint.title} من ${complaint.parentName}');

      // إرسال إشعار للأدمن
      await _notificationService.sendEventNotification(
        eventId: 'complaint_created',
        eventData: {
          'parentName': complaint.parentName,
          'parentId': complaint.parentId,
          'title': complaint.title,
          'description': complaint.description,
          'priority': complaint.priority.toString().split('.').last,
          'studentName': complaint.studentName ?? 'غير محدد',
          'complaintId': complaint.id,
          'createdAt': complaint.createdAt.toIso8601String(),
        },
      );

      debugPrint('✅ تم إرسال إشعار الشكوى الجديدة');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الشكوى الجديدة: $e');
    }
  }

  /// مراقبة الطلاب الجدد
  void _monitorNewStudents() {
    final subscription = _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewStudent(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة طالب جديد
  Future<void> _handleNewStudent(Map<String, dynamic> studentData) async {
    try {
      final student = StudentModel.fromMap(studentData);
      
      debugPrint('👨‍🎓 طالب جديد: ${student.name} من ولي الأمر ${student.parentName}');

      // إرسال إشعار للأدمن
      await _notificationService.sendEventNotification(
        eventId: 'student_created',
        eventData: {
          'studentName': student.name,
          'studentId': student.id,
          'parentName': student.parentName,
          'parentId': student.parentId,
          'schoolName': student.schoolName,
          'grade': student.grade,
          'busRoute': student.busRoute,
          'createdAt': student.createdAt.toIso8601String(),
        },
      );

      debugPrint('✅ تم إرسال إشعار الطالب الجديد');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الطالب الجديد: $e');
    }
  }

  /// مراقبة تقارير الغياب
  void _monitorAbsenceReports() {
    final subscription = _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewAbsenceReport(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة تقرير غياب جديد
  Future<void> _handleNewAbsenceReport(Map<String, dynamic> absenceData) async {
    try {
      final absence = AbsenceModel.fromMap(absenceData);
      
      debugPrint('📅 تقرير غياب جديد: ${absence.studentName} بتاريخ ${absence.date}');

      // إرسال إشعار للأدمن والمشرف
      await _notificationService.sendEventNotification(
        eventId: 'absence_reported',
        eventData: {
          'studentName': absence.studentName,
          'studentId': absence.studentId,
          'parentId': absence.parentId,
          'supervisorId': absence.supervisorId,
          'date': absence.date.toIso8601String(),
          'reason': absence.reason,
          'type': absence.type.toString().split('.').last,
          'absenceId': absence.id,
        },
      );

      debugPrint('✅ تم إرسال إشعار تقرير الغياب');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تقرير الغياب: $e');
    }
  }

  /// مراقبة تقييمات المشرفين
  void _monitorSupervisorEvaluations() {
    final subscription = _firestore
        .collection('supervisor_evaluations')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewSupervisorEvaluation(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة تقييم مشرف جديد
  Future<void> _handleNewSupervisorEvaluation(Map<String, dynamic> evaluationData) async {
    try {
      final evaluation = SupervisorEvaluationModel.fromMap(evaluationData);
      
      debugPrint('⭐ تقييم مشرف جديد: ${evaluation.supervisorName} من ${evaluation.parentName}');

      // إرسال إشعار للأدمن
      await _notificationService.sendEventNotification(
        eventId: 'supervisor_evaluated',
        eventData: {
          'supervisorName': evaluation.supervisorName,
          'supervisorId': evaluation.supervisorId,
          'parentName': evaluation.parentName,
          'parentId': evaluation.parentId,
          'studentName': evaluation.studentName,
          'averageRating': evaluation.averageRating.toString(),
          'month': evaluation.month.toString(),
          'year': evaluation.year.toString(),
          'evaluationId': evaluation.id,
        },
      );

      debugPrint('✅ تم إرسال إشعار تقييم المشرف');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تقييم المشرف: $e');
    }
  }

  /// مراقبة الرحلات (QR Code scanning)
  void _monitorTrips() {
    final subscription = _firestore
        .collection('trips')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewTrip(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة رحلة جديدة (مسح QR Code)
  Future<void> _handleNewTrip(Map<String, dynamic> tripData) async {
    try {
      final trip = TripModel.fromMap(tripData);
      
      debugPrint('🚌 رحلة جديدة: ${trip.studentName} - ${trip.action}');

      String eventId;
      Map<String, dynamic> eventData = {
        'studentName': trip.studentName,
        'studentId': trip.studentId,
        'supervisorName': trip.supervisorName,
        'supervisorId': trip.supervisorId,
        'busRoute': trip.busRoute,
        'time': trip.timestamp.toIso8601String(),
        'tripId': trip.id,
      };

      // تحديد نوع الإشعار بناءً على نوع الرحلة
      switch (trip.action) {
        case TripAction.boardBus:
        case TripAction.boardBusToSchool:
        case TripAction.boardBusToHome:
          eventId = 'student_boarded_bus';
          break;
        case TripAction.arriveAtSchool:
          eventId = 'student_at_school';
          break;
        case TripAction.arriveAtHome:
          eventId = 'student_at_home';
          break;
        default:
          return; // تجاهل الأحداث الأخرى
      }

      // الحصول على معرف ولي الأمر
      final studentDoc = await _firestore.collection('students').doc(trip.studentId).get();
      final parentId = studentDoc.data()?['parentId'];
      
      if (parentId != null) {
        eventData['parentId'] = parentId;
        
        // إرسال إشعار لولي الأمر
        await _notificationService.sendEventNotification(
          eventId: eventId,
          eventData: eventData,
          specificRecipientId: parentId,
        );

        debugPrint('✅ تم إرسال إشعار الرحلة لولي الأمر');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة الرحلة الجديدة: $e');
    }
  }

  /// مراقبة المستخدمين الجدد
  void _monitorNewUsers() {
    final subscription = _firestore
        .collection('users')
        .where('userType', isEqualTo: 'parent')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewUser(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة مستخدم جديد
  Future<void> _handleNewUser(Map<String, dynamic> userData) async {
    try {
      final user = UserModel.fromMap(userData);
      
      if (user.userType == UserType.parent) {
        debugPrint('👤 ولي أمر جديد: ${user.name}');

        // إرسال إشعار للأدمن
        await _notificationService.sendEventNotification(
          eventId: 'new_parent_account',
          eventData: {
            'parentName': user.name,
            'parentId': user.id,
            'parentEmail': user.email,
            'parentPhone': user.phone,
            'createdAt': user.createdAt.toIso8601String(),
          },
        );

        debugPrint('✅ تم إرسال إشعار المستخدم الجديد');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة المستخدم الجديد: $e');
    }
  }

  /// مراقبة تعيينات المشرفين
  void _monitorSupervisorAssignments() {
    final subscription = _firestore
        .collection('supervisor_assignments')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewSupervisorAssignment(change.doc.data()!);
        }
      }
    });

    _subscriptions.add(subscription);
  }

  /// معالجة تعيين مشرف جديد
  Future<void> _handleNewSupervisorAssignment(Map<String, dynamic> assignmentData) async {
    try {
      debugPrint('👩‍🏫 تعيين مشرف جديد في باص');

      // إرسال إشعار للمشرف
      await _notificationService.sendEventNotification(
        eventId: 'supervisor_assigned_to_bus',
        eventData: {
          'supervisorId': assignmentData['supervisorId'],
          'supervisorName': assignmentData['supervisorName'] ?? 'المشرف',
          'busId': assignmentData['busId'],
          'busRoute': assignmentData['busRoute'] ?? assignmentData['busId'],
          'assignedAt': DateTime.now().toIso8601String(),
        },
        specificRecipientId: assignmentData['supervisorId'],
      );

      debugPrint('✅ تم إرسال إشعار تعيين المشرف');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تعيين المشرف: $e');
    }
  }

  /// مراقبة إكمال البروفايل
  void _monitorProfileCompletion() {
    final subscription = _firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleProfileCompletion(change.doc);
        }
      }
    });

    _subscriptions.add(subscription);
    debugPrint('🔍 بدء مراقبة إكمال البروفايل');
  }

  /// معالجة إكمال البروفايل
  Future<void> _handleProfileCompletion(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final user = UserModel.fromMap(data);

      // التحقق من إكمال البروفايل (جميع الحقول المطلوبة مملوءة)
      final isProfileComplete = _isProfileComplete(user);
      final wasProfileIncomplete = data['isProfileComplete'] == false;

      if (isProfileComplete && wasProfileIncomplete) {
        // تحديث حالة البروفايل
        await doc.reference.update({'isProfileComplete': true});

        // إرسال إشعار للأدمن
        await _notificationService.sendEventNotification(
          eventId: 'profile_completed',
          eventData: {
            'userId': user.id,
            'userName': user.name,
            'userType': user.userType.toString().split('.').last,
            'completedAt': DateTime.now().toIso8601String(),
          },
        );

        debugPrint('✅ تم إرسال إشعار إكمال البروفايل للمستخدم: ${user.name}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة إكمال البروفايل: $e');
    }
  }

  /// التحقق من إكمال البروفايل
  bool _isProfileComplete(UserModel user) {
    return user.name.isNotEmpty &&
           user.email.isNotEmpty &&
           user.phone.isNotEmpty &&
           user.userType != null;
  }

  /// مراقبة تعيين الطلاب في خطوط السير
  void _monitorStudentBusAssignments() {
    final subscription = _firestore
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleStudentBusAssignment(change.doc);
        }
      }
    });

    _subscriptions.add(subscription);
    debugPrint('🔍 بدء مراقبة تعيين الطلاب في خطوط السير');
  }

  /// معالجة تعيين طالب في خط سير
  Future<void> _handleStudentBusAssignment(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final student = StudentModel.fromMap(data);

      // التحقق من تغيير خط السير (مقارنة بسيطة)
      if (student.busRoute.isNotEmpty) {
        // إرسال إشعار لولي الأمر
        await _notificationService.sendEventNotification(
          eventId: 'student_assigned_to_bus',
          eventData: {
            'studentId': student.id,
            'studentName': student.name,
            'parentId': student.parentId,
            'busRoute': student.busRoute,
            'assignedAt': DateTime.now().toIso8601String(),
          },
          specificRecipientId: student.parentId,
        );

        debugPrint('✅ تم إرسال إشعار تعيين الطالب ${student.name} في خط السير ${student.busRoute}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تعيين الطالب في خط السير: $e');
    }
  }

  /// مراقبة حذف الطلاب
  void _monitorStudentDeletion() {
    final subscription = _firestore
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _handleStudentDeletion(change.doc);
        }
      }
    });

    _subscriptions.add(subscription);
    debugPrint('🔍 بدء مراقبة حذف الطلاب');
  }

  /// معالجة حذف طالب
  Future<void> _handleStudentDeletion(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final student = StudentModel.fromMap(data);

      // إرسال إشعار لولي الأمر
      await _notificationService.sendEventNotification(
        eventId: 'student_removed',
        eventData: {
          'studentId': student.id,
          'studentName': student.name,
          'parentId': student.parentId,
          'removedAt': DateTime.now().toIso8601String(),
          'reason': 'تم حذف الطالب من النظام',
        },
        specificRecipientId: student.parentId,
      );

      debugPrint('✅ تم إرسال إشعار حذف الطالب ${student.name} لولي الأمر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حذف الطالب: $e');
    }
  }

  /// مراقبة تحديث بيانات الطلاب للمشرفين
  void _monitorStudentDataUpdatesForSupervisors() {
    final subscription = _firestore
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleStudentDataUpdateForSupervisor(change.doc);
        }
      }
    });

    _subscriptions.add(subscription);
    debugPrint('🔍 بدء مراقبة تحديث بيانات الطلاب للمشرفين');
  }

  /// معالجة تحديث بيانات طالب للمشرف
  Future<void> _handleStudentDataUpdateForSupervisor(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final student = StudentModel.fromMap(data);

      // الحصول على المشرف المسؤول عن هذا الطالب
      final supervisorQuery = await _firestore
          .collection('supervisor_assignments')
          .where('busRoute', isEqualTo: student.busRoute)
          .where('isActive', isEqualTo: true)
          .get();

      if (supervisorQuery.docs.isNotEmpty) {
        final supervisorId = supervisorQuery.docs.first.data()['supervisorId'];

        // إرسال إشعار للمشرف
        await _notificationService.sendEventNotification(
          eventId: 'student_data_updated',
          eventData: {
            'studentId': student.id,
            'studentName': student.name,
            'busRoute': student.busRoute,
            'updatedAt': DateTime.now().toIso8601String(),
            'supervisorId': supervisorId,
          },
          specificRecipientId: supervisorId,
        );

        debugPrint('✅ تم إرسال إشعار تحديث بيانات الطالب ${student.name} للمشرف');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث بيانات الطالب للمشرف: $e');
    }
  }

  /// إيقاف مراقبة الأحداث
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isInitialized = false;
    debugPrint('🔍 تم إيقاف مراقبة الأحداث');
  }

  /// إعادة تشغيل مراقبة الأحداث
  Future<void> restart() async {
    dispose();
    await initialize();
  }

  /// الحصول على حالة الخدمة
  bool get isInitialized => _isInitialized;
  int get activeSubscriptions => _subscriptions.length;
}
