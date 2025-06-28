import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/student_model.dart';
import '../models/trip_model.dart';
import '../models/bus_model.dart';
import '../models/complaint_model.dart';
import '../models/parent_profile_model.dart';
import '../models/absence_model.dart';
import '../models/user_model.dart';
import '../models/survey_model.dart';
import '../models/supervisor_assignment_model.dart';
import '../models/student_behavior_model.dart';


class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // User Data Methods
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('فشل في الحصول على بيانات المستخدم: $e');
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث بيانات المستخدم: $e');
    }
  }

  // Parent-Student Relationship Methods

  /// Add a child to parent using a simpler approach
  Future<void> addChildToParent(String parentId, Map<String, dynamic> childData) async {
    try {
      debugPrint('➕ Adding child to parent: $parentId');

      // Create a clean child data object
      final cleanChildData = Map<String, dynamic>.from(childData);
      cleanChildData['addedAt'] = DateTime.now().toIso8601String();
      cleanChildData['updatedAt'] = DateTime.now().toIso8601String();

      // Get current parent data
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (parentDoc.exists) {
        final parentData = parentDoc.data() as Map<String, dynamic>;
        final List<dynamic> currentChildren = List.from(parentData['children'] ?? []);

        // Add new child to the list
        currentChildren.add(cleanChildData);

        // Update parent document
        await _firestore.collection('users').doc(parentId).update({
          'children': currentChildren,
          'childrenCount': currentChildren.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Child added to parent children list successfully');
      } else {
        // Create new parent document with first child
        await _firestore.collection('users').doc(parentId).set({
          'children': [cleanChildData],
          'childrenCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created new parent document with first child');
      }
    } catch (e) {
      debugPrint('❌ Failed to add child to parent: $e');
      throw Exception('فشل في إضافة الطفل لقائمة ولي الأمر: $e');
    }
  }

  /// Get parent's children from users collection
  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    try {
      final parentDoc = await _firestore.collection('users').doc(parentId).get();

      if (parentDoc.exists) {
        final parentData = parentDoc.data() as Map<String, dynamic>;
        final List<dynamic> children = parentData['children'] ?? [];

        return children.map((child) => child as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      throw Exception('فشل في جلب أطفال ولي الأمر: $e');
    }
  }

  /// Alternative approach: Create a separate parent-child relationship document
  Future<void> syncStudentWithParent(String parentId, StudentModel student) async {
    try {
      debugPrint('🔄 Creating parent-child relationship for ${student.name}');

      // Instead of using arrays, create a separate document for the relationship
      final relationshipId = '${parentId}_${student.id}';

      await _firestore.collection('parent_children').doc(relationshipId).set({
        'parentId': parentId,
        'studentId': student.id,
        'studentName': student.name,
        'studentGrade': student.grade,
        'studentSchool': student.schoolName,
        'studentRoute': student.busRoute,
        'studentPhoto': student.photoUrl,
        'studentQR': student.qrCode,
        'studentStatus': student.currentStatus.toString().split('.').last,
        'isActive': student.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update parent's simple counter
      await _firestore.collection('users').doc(parentId).update({
        'hasChildren': true,
        'lastChildAdded': student.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Parent-child relationship created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create parent-child relationship: $e');
      throw Exception('فشل في ربط الطالب بولي الأمر: $e');
    }
  }

  /// Get parent's children using the relationship collection
  Future<List<Map<String, dynamic>>> getParentChildrenFromRelationships(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('parent_children')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['studentId'],
          'name': data['studentName'],
          'grade': data['studentGrade'],
          'schoolName': data['studentSchool'],
          'busRoute': data['studentRoute'],
          'photoUrl': data['studentPhoto'],
          'qrCode': data['studentQR'],
          'currentStatus': data['studentStatus'],
          'isActive': data['isActive'],
          'relationshipId': doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get parent children from relationships: $e');
      return [];
    }
  }

  // Students Collection Methods

  // Add new student with enhanced parent relationship
  Future<String> addStudent(StudentModel student) async {
    try {
      // Generate ID if not provided
      final studentId = student.id.isEmpty ? _uuid.v4() : student.id;

      // Generate QR code if not provided
      final qrCode = student.qrCode.isEmpty ? await generateQRCode() : student.qrCode;

      // Create student with generated values
      final studentWithId = student.copyWith(
        id: studentId,
        qrCode: qrCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to students collection
      await _firestore
          .collection('students')
          .doc(studentId)
          .set(studentWithId.toMap());

      // Sync with parent's children list (with fallback)
      try {
        await syncStudentWithParent(student.parentId, studentWithId);
      } catch (syncError) {
        debugPrint('⚠️ Failed to sync with parent, but student was created: $syncError');
        // Continue anyway - student is created, sync can be done later
      }

      debugPrint('✅ Student added successfully: ${student.name} with QR: $qrCode');
      return studentId;
    } catch (e) {
      throw Exception('خطأ في إضافة الطالب: $e');
    }
  }

  // Get student by ID
  Future<StudentModel?> getStudent(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات الطالب: $e');
    }
  }

  // Get student by QR code
  Future<StudentModel?> getStudentByQRCode(String qrCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('qrCode', isEqualTo: qrCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return StudentModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في البحث عن الطالب: $e');
    }
  }

  // Get students by parent ID
  Stream<List<StudentModel>> getStudentsByParent(String parentId) {
    return _firestore
        .collection('students')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get all students (for admin)
  Stream<List<StudentModel>> getAllStudents() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get students by bus ID (simplified to avoid index issues)
  Stream<List<StudentModel>> getStudentsByBusId(String busId) {
    return _firestore
        .collection('students')
        .where('busId', isEqualTo: busId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList();

          // Sort manually to avoid index requirement
          students.sort((a, b) => a.name.compareTo(b.name));
          return students;
        });
  }

  // Update student
  Future<void> updateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.id)
          .update(student.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات الطالب: $e');
    }
  }

  // Update student status
  Future<void> updateStudentStatus(String studentId, StudentStatus status) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'currentStatus': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الطالب: $e');
    }
  }

  // Delete student (soft delete)
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('خطأ في حذف الطالب: $e');
    }
  }

  // Trip Collection Methods

  // Record trip action with enhanced logging
  Future<void> recordTrip(TripModel trip) async {
    try {
      // Ensure all required fields are present
      final tripData = trip.toMap();

      // Add additional metadata for better tracking
      tripData['createdAt'] = Timestamp.fromDate(DateTime.now());
      tripData['source'] = 'mobile_app';

      // Log the trip data for debugging
      debugPrint('🚌 Recording trip: ${trip.studentName} - ${trip.actionDisplayText}');
      debugPrint('📍 Trip data: $tripData');

      await _firestore.collection('trips').doc(trip.id).set(tripData);

      debugPrint('✅ Trip recorded successfully');
    } catch (e) {
      debugPrint('❌ Error recording trip: $e');
      throw Exception('خطأ في تسجيل الرحلة: $e');
    }
  }

  // Get trips by student ID
  Stream<List<TripModel>> getTripsByStudent(String studentId) {
    return _firestore
        .collection('trips')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data()))
            .toList());
  }

  // Get trips by date range
  Stream<List<TripModel>> getTripsByDateRange(DateTime startDate, DateTime endDate) {
    try {
      debugPrint('🔍 Getting trips from ${startDate.toString()} to ${endDate.toString()}');

      return _firestore
          .collection('trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('❌ Error in getTripsByDateRange: $error');
            // If compound index is missing, try simpler query
            if (error.toString().contains('index')) {
              debugPrint('🔄 Trying simpler query without orderBy...');
              return _firestore
                  .collection('trips')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
                  .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
                  .snapshots();
            }
            throw error;
          })
          .map((snapshot) {
            debugPrint('📊 Found ${snapshot.docs.length} trips in date range');
            return snapshot.docs
                .map((doc) {
                  try {
                    return TripModel.fromMap(doc.data());
                  } catch (e) {
                    debugPrint('❌ Error parsing trip ${doc.id}: $e');
                    return null;
                  }
                })
                .where((trip) => trip != null)
                .cast<TripModel>()
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error setting up getTripsByDateRange: $e');
      // Return empty stream on error
      return Stream.value(<TripModel>[]);
    }
  }

  // Get trips by student ID and date (simpler query)
  Stream<List<TripModel>> getTripsByStudentAndDate(String studentId, DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('🔍 Getting trips for student $studentId on ${date.toString()}');

      return _firestore
          .collection('trips')
          .where('studentId', isEqualTo: studentId)
          .snapshots()
          .map((snapshot) {
            final allTrips = snapshot.docs
                .map((doc) {
                  try {
                    return TripModel.fromMap(doc.data());
                  } catch (e) {
                    debugPrint('❌ Error parsing trip ${doc.id}: $e');
                    return null;
                  }
                })
                .where((trip) => trip != null)
                .cast<TripModel>()
                .toList();

            // Filter by date locally
            final filteredTrips = allTrips.where((trip) {
              return trip.timestamp.isAfter(startOfDay) &&
                     trip.timestamp.isBefore(endOfDay);
            }).toList();

            // Sort by timestamp descending
            filteredTrips.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            debugPrint('📊 Found ${filteredTrips.length} trips for student on date');
            return filteredTrips;
          });
    } catch (e) {
      debugPrint('❌ Error in getTripsByStudentAndDate: $e');
      return Stream.value(<TripModel>[]);
    }
  }

  // Generate unique QR code for student (sequential starting from 1000)
  Future<String> generateQRCode() async {
    try {
      // Get the current counter from Firestore
      final counterDoc = await _firestore
          .collection('counters')
          .doc('student_qr_code')
          .get();

      int nextNumber = 1000; // Start from 1000

      if (counterDoc.exists) {
        final currentValue = counterDoc.data()?['value'] ?? 999;
        nextNumber = currentValue + 1;
      }

      // Update the counter
      await _firestore
          .collection('counters')
          .doc('student_qr_code')
          .set({'value': nextNumber});

      // Return the QR code as string
      final qrCode = nextNumber.toString();
      debugPrint('✅ Generated QR code: $qrCode');
      return qrCode;
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
      // Fallback to timestamp-based code if counter fails
      final fallbackCode = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
      debugPrint('🔄 Using fallback QR code: $fallbackCode');
      return fallbackCode;
    }
  }

  // Generate unique QR code synchronously (for compatibility)
  String generateQRCodeSync() {
    // Generate a simple sequential number based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCode = (1000 + (timestamp % 9000)).toString();
    return qrCode;
  }

  // Generate unique trip ID
  String generateTripId() {
    return _uuid.v4();
  }

  // Bus Collection Methods

  // Add new bus
  Future<void> addBus(BusModel bus) async {
    try {
      await _firestore
          .collection('buses')
          .doc(bus.id)
          .set(bus.toMap());
      debugPrint('✅ Bus added successfully: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error adding bus: $e');
      throw Exception('خطأ في إضافة السيارة: $e');
    }
  }

  // Get bus by ID
  Future<BusModel?> getBus(String busId) async {
    try {
      final doc = await _firestore.collection('buses').doc(busId).get();
      if (doc.exists) {
        return BusModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting bus: $e');
      throw Exception('خطأ في جلب بيانات السيارة: $e');
    }
  }

  // Get bus by route
  Future<BusModel?> getBusByRoute(String route) async {
    try {
      final querySnapshot = await _firestore
          .collection('buses')
          .where('route', isEqualTo: route)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return BusModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting bus by route: $e');
      throw Exception('خطأ في البحث عن السيارة: $e');
    }
  }

  // Get all buses (for admin) - simplified query to avoid index issues
  Stream<List<BusModel>> getAllBuses() {
    return _firestore
        .collection('buses')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          try {
            final buses = snapshot.docs
                .map((doc) {
                  try {
                    return BusModel.fromMap(doc.data());
                  } catch (e) {
                    debugPrint('❌ Error parsing bus document ${doc.id}: $e');
                    return null;
                  }
                })
                .where((bus) => bus != null)
                .cast<BusModel>()
                .toList();

            // Sort locally to avoid compound index requirement
            buses.sort((a, b) => a.plateNumber.compareTo(b.plateNumber));
            debugPrint('✅ Loaded ${buses.length} buses successfully');
            return buses;
          } catch (e) {
            debugPrint('❌ Error processing buses snapshot: $e');
            return <BusModel>[];
          }
        })
        .handleError((error) {
          debugPrint('❌ Error in getAllBuses stream: $error');
          return <BusModel>[];
        });
  }

  // Update bus
  Future<void> updateBus(BusModel bus) async {
    try {
      await _firestore
          .collection('buses')
          .doc(bus.id)
          .update(bus.copyWith(updatedAt: DateTime.now()).toMap());
      debugPrint('✅ Bus updated successfully: ${bus.plateNumber}');
    } catch (e) {
      debugPrint('❌ Error updating bus: $e');
      throw Exception('خطأ في تحديث بيانات السيارة: $e');
    }
  }

  // Delete bus (soft delete)
  Future<void> deleteBus(String busId) async {
    try {
      await _firestore.collection('buses').doc(busId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ Bus deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting bus: $e');
      throw Exception('خطأ في حذف السيارة: $e');
    }
  }

  // Get available routes
  Future<List<String>> getAvailableRoutes() async {
    try {
      final querySnapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get();

      final routes = querySnapshot.docs
          .map((doc) => doc.data()['route'] as String)
          .where((route) => route.isNotEmpty)
          .toSet()
          .toList();

      routes.sort();
      return routes;
    } catch (e) {
      debugPrint('❌ Error getting routes: $e');
      return [];
    }
  }

  // Generate unique bus ID
  String generateBusId() {
    return _uuid.v4();
  }

  // Get bus information for a student
  Future<BusModel?> getBusForStudent(String studentId) async {
    try {
      // First get the student to find their busId
      final student = await getStudent(studentId);
      if (student == null || student.busId.isEmpty) {
        return null;
      }

      // Then get the bus information
      return await getBus(student.busId);
    } catch (e) {
      debugPrint('❌ Error getting bus for student: $e');
      return null;
    }
  }

  // Assign bus to student
  Future<void> assignBusToStudent(String studentId, String busId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'busId': busId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ Bus assigned to student successfully');
    } catch (e) {
      debugPrint('❌ Error assigning bus to student: $e');
      throw Exception('خطأ في تعيين السيارة للطالب: $e');
    }
  }

  // Get students assigned to a specific bus
  Stream<List<StudentModel>> getStudentsByBus(String busId) {
    return _firestore
        .collection('students')
        .where('busId', isEqualTo: busId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Get all students currently on buses (alias for supervisor screen)
  Stream<List<StudentModel>> getStudentsOnBus() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .where('busId', isNotEqualTo: '')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data()))
            .toList());
  }

  // Complaints Collection Methods

  /// Add new complaint
  Future<String> addComplaint(ComplaintModel complaint) async {
    try {
      // Generate ID if not provided
      final complaintId = complaint.id.isEmpty ? _uuid.v4() : complaint.id;

      // Create complaint with generated ID
      final complaintWithId = complaint.copyWith(
        id: complaintId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to complaints collection
      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .set(complaintWithId.toMap());

      debugPrint('✅ Complaint added successfully: ${complaint.title}');
      return complaintId;
    } catch (e) {
      debugPrint('❌ Error adding complaint: $e');
      throw Exception('خطأ في إضافة الشكوى: $e');
    }
  }

  /// Get complaint by ID
  Future<ComplaintModel?> getComplaint(String complaintId) async {
    try {
      final doc = await _firestore.collection('complaints').doc(complaintId).get();
      if (doc.exists) {
        return ComplaintModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting complaint: $e');
      throw Exception('خطأ في جلب بيانات الشكوى: $e');
    }
  }

  /// Get complaints by parent ID (simplified query to avoid index issues)
  Stream<List<ComplaintModel>> getComplaintsByParent(String parentId) {
    return _firestore
        .collection('complaints')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid compound index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get all complaints (for admin) - simplified query
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get complaints by status - simplified query
  Stream<List<ComplaintModel>> getComplaintsByStatus(ComplaintStatus status) {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: status.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Get complaints by priority - simplified query
  Stream<List<ComplaintModel>> getComplaintsByPriority(ComplaintPriority priority) {
    return _firestore
        .collection('complaints')
        .where('priority', isEqualTo: priority.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Update complaint
  Future<void> updateComplaint(ComplaintModel complaint) async {
    try {
      await _firestore
          .collection('complaints')
          .doc(complaint.id)
          .update(complaint.copyWith(updatedAt: DateTime.now()).toMap());
      debugPrint('✅ Complaint updated successfully: ${complaint.title}');
    } catch (e) {
      debugPrint('❌ Error updating complaint: $e');
      throw Exception('خطأ في تحديث الشكوى: $e');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus(String complaintId, ComplaintStatus status) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Complaint status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating complaint status: $e');
      throw Exception('خطأ في تحديث حالة الشكوى: $e');
    }
  }

  /// Add admin response to complaint
  Future<void> addComplaintResponse(String complaintId, String response, String adminId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'adminResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
        'assignedTo': adminId,
        'status': ComplaintStatus.resolved.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Admin response added successfully');
    } catch (e) {
      debugPrint('❌ Error adding admin response: $e');
      throw Exception('خطأ في إضافة رد الإدارة: $e');
    }
  }

  /// Delete complaint (soft delete)
  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Complaint deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting complaint: $e');
      throw Exception('خطأ في حذف الشكوى: $e');
    }
  }

  /// Get complaints statistics
  Future<Map<String, int>> getComplaintsStats() async {
    try {
      final snapshot = await _firestore
          .collection('complaints')
          .where('isActive', isEqualTo: true)
          .get();

      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data()))
          .toList();

      return {
        'total': complaints.length,
        'pending': complaints.where((c) => c.status == ComplaintStatus.pending).length,
        'inProgress': complaints.where((c) => c.status == ComplaintStatus.inProgress).length,
        'resolved': complaints.where((c) => c.status == ComplaintStatus.resolved).length,
        'closed': complaints.where((c) => c.status == ComplaintStatus.closed).length,
        'urgent': complaints.where((c) => c.priority == ComplaintPriority.urgent).length,
        'high': complaints.where((c) => c.priority == ComplaintPriority.high).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting complaints stats: $e');
      return {};
    }
  }

  /// Get pending complaints for admin review
  Stream<List<ComplaintModel>> getPendingComplaints() {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return complaints;
        });
  }

  /// Generate unique complaint ID
  String generateComplaintId() {
    return _uuid.v4();
  }

  /// Test Firebase connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Firebase connection...');

      // Try to read from a simple collection
      await _firestore
          .collection('test')
          .doc('connection')
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Firebase connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }

  /// Get buses with fallback
  Future<List<BusModel>> getBusesWithFallback() async {
    try {
      debugPrint('🔍 Getting buses with fallback...');

      final snapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 15));

      final buses = snapshot.docs
          .map((doc) {
            try {
              return BusModel.fromMap(doc.data());
            } catch (e) {
              debugPrint('❌ Error parsing bus document ${doc.id}: $e');
              return null;
            }
          })
          .where((bus) => bus != null)
          .cast<BusModel>()
          .toList();

      buses.sort((a, b) => a.plateNumber.compareTo(b.plateNumber));
      debugPrint('✅ Loaded ${buses.length} buses with fallback');
      return buses;
    } catch (e) {
      debugPrint('❌ Error getting buses with fallback: $e');
      // Return mock data for testing
      debugPrint('📝 Returning mock buses for testing...');
      return _getMockBuses();
    }
  }

  /// Get mock buses for testing/fallback
  List<BusModel> _getMockBuses() {
    return [
      BusModel(
        id: 'mock_bus_1',
        plateNumber: 'أ ب ج 123',
        description: 'سيارة نقل طلاب - خط الشمال',
        driverName: 'أحمد محمد',
        driverPhone: '0501234567',
        route: 'خط الشمال',
        capacity: 30,
        hasAirConditioning: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      BusModel(
        id: 'mock_bus_2',
        plateNumber: 'د هـ و 456',
        description: 'سيارة نقل طلاب - خط الجنوب',
        driverName: 'محمد علي',
        driverPhone: '0507654321',
        route: 'خط الجنوب',
        capacity: 25,
        hasAirConditioning: false,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      BusModel(
        id: 'mock_bus_3',
        plateNumber: 'ز ح ط 789',
        description: 'سيارة نقل طلاب - خط الشرق',
        driverName: 'عبدالله سالم',
        driverPhone: '0509876543',
        route: 'خط الشرق',
        capacity: 35,
        hasAirConditioning: true,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Trip Management Methods
  Future<void> addTrip(Map<String, dynamic> tripData) async {
    try {
      await _firestore.collection('trips').add({
        ...tripData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Trip added to database');
    } catch (e) {
      debugPrint('❌ Error adding trip: $e');
      throw Exception('فشل في إضافة الرحلة: $e');
    }
  }

  Future<void> updateSupervisorTripStatus(String supervisorId, Map<String, dynamic> tripData) async {
    try {
      // Check if supervisor document exists first
      final docRef = _firestore.collection('supervisors').doc(supervisorId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update existing document
        await docRef.update({
          'currentTrip': tripData,
          'lastTripUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Supervisor trip status updated');
      } else {
        // Create new supervisor document
        await docRef.set({
          'id': supervisorId,
          'currentTrip': tripData,
          'lastTripUpdate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Supervisor document created with trip status');
      }
    } catch (e) {
      debugPrint('❌ Error updating supervisor trip status: $e');
      throw Exception('فشل في تحديث حالة رحلة المشرف: $e');
    }
  }

  // Get current trip status for supervisor
  Future<Map<String, dynamic>?> getSupervisorTripStatus(String supervisorId) async {
    try {
      final doc = await _firestore.collection('supervisors').doc(supervisorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['currentTrip'] as Map<String, dynamic>?;
      } else {
        // Create supervisor document if it doesn't exist
        await createSupervisorIfNotExists(supervisorId);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting supervisor trip status: $e');
      return null;
    }
  }

  // Create supervisor document if it doesn't exist
  Future<void> createSupervisorIfNotExists(String supervisorId) async {
    try {
      final docRef = _firestore.collection('supervisors').doc(supervisorId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'id': supervisorId,
          'currentTrip': null,
          'lastTripUpdate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        debugPrint('✅ Supervisor document created: $supervisorId');
      }
    } catch (e) {
      debugPrint('❌ Error creating supervisor document: $e');
    }
  }

  // Get all trips for supervisor
  Stream<List<Map<String, dynamic>>> getSupervisorTrips(String supervisorId) {
    return _firestore
        .collection('trips')
        .where('supervisorId', isEqualTo: supervisorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Parent Profile Management Methods
  Future<void> saveParentProfile(ParentProfileModel profile) async {
    try {
      await _firestore.collection('parent_profiles').doc(profile.id).set(profile.toMap());
      debugPrint('✅ Parent profile saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving parent profile: $e');
      throw Exception('فشل في حفظ بيانات الوالد: $e');
    }
  }

  Future<ParentProfileModel?> getParentProfile(String parentId) async {
    try {
      final doc = await _firestore.collection('parent_profiles').doc(parentId).get();
      if (doc.exists) {
        return ParentProfileModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting parent profile: $e');
      return null;
    }
  }

  Future<void> updateParentProfile(String parentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('parent_profiles').doc(parentId).update({
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Parent profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating parent profile: $e');
      throw Exception('فشل في تحديث بيانات الوالد: $e');
    }
  }

  Stream<List<ParentProfileModel>> getAllParentProfiles() {
    return _firestore
        .collection('parent_profiles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
            ParentProfileModel.fromMap({
              'id': doc.id,
              ...doc.data(),
            })
        ).toList());
  }

  Future<bool> isParentProfileComplete(String parentId) async {
    try {
      final profile = await getParentProfile(parentId);
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      debugPrint('❌ Error checking profile completion: $e');
      return false;
    }
  }

  // ==================== ABSENCE MANAGEMENT ====================

  // Create absence report
  Future<void> createAbsence(AbsenceModel absence) async {
    try {
      final absenceData = absence.toMap();
      debugPrint('📝 Creating absence: ${absence.studentName} - Status: ${absence.status.toString().split('.').last}');
      debugPrint('📊 Absence data: $absenceData');

      await _firestore.collection('absences').doc(absence.id).set(absenceData);
      debugPrint('✅ Absence created successfully with ID: ${absence.id}');
    } catch (e) {
      debugPrint('❌ Error creating absence: $e');
      throw Exception('فشل في إنشاء تقرير الغياب: $e');
    }
  }

  // Update absence
  Future<void> updateAbsence(AbsenceModel absence) async {
    try {
      await _firestore.collection('absences').doc(absence.id).update(absence.toMap());
      debugPrint('✅ Absence updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating absence: $e');
      throw Exception('فشل في تحديث تقرير الغياب: $e');
    }
  }

  // Delete absence
  Future<void> deleteAbsence(String absenceId) async {
    try {
      await _firestore.collection('absences').doc(absenceId).delete();
      debugPrint('✅ Absence deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting absence: $e');
      throw Exception('فشل في حذف تقرير الغياب: $e');
    }
  }

  // Get absence by ID
  Future<AbsenceModel?> getAbsenceById(String absenceId) async {
    try {
      final doc = await _firestore.collection('absences').doc(absenceId).get();
      if (doc.exists) {
        return AbsenceModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting absence: $e');
      return null;
    }
  }

  // Get all absences
  Stream<List<AbsenceModel>> getAllAbsences() {
    return _firestore
        .collection('absences')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList());
  }

  // Get absences by student
  Stream<List<AbsenceModel>> getAbsencesByStudent(String studentId) {
    return _firestore
        .collection('absences')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList());
  }

  // Get absences by parent
  Stream<List<AbsenceModel>> getAbsencesByParent(String parentId) {
    return _firestore
        .collection('absences')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .toList();

          // Sort locally to avoid index requirement
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get pending absences for admin approval
  Stream<List<AbsenceModel>> getPendingAbsences() {
    debugPrint('🔍 Setting up pending absences stream...');

    return _firestore
        .collection('absences')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Error in getPendingAbsences stream: $error');
        })
        .map((snapshot) {
          debugPrint('📡 Received snapshot with ${snapshot.docs.length} documents');

          final absences = <AbsenceModel>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              debugPrint('📋 Processing document ${doc.id}:');
              debugPrint('   Student: ${data['studentName']}');
              debugPrint('   Status: ${data['status']}');
              debugPrint('   Parent: ${data['parentId']}');
              debugPrint('   Created: ${data['createdAt']}');

              final absence = AbsenceModel.fromMap(data);
              absences.add(absence);
              debugPrint('✅ Successfully parsed absence for ${absence.studentName}');
            } catch (e) {
              debugPrint('❌ Error parsing document ${doc.id}: $e');
            }
          }

          debugPrint('📊 Final pending absences count: ${absences.length}');
          return absences;
        });
  }

  // Get today's absences
  Stream<List<AbsenceModel>> getTodayAbsences() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _firestore
        .collection('absences')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .where((absence) => absence.status == AbsenceStatus.approved)
              .toList();

          // Sort locally
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get recent absence notifications (last 24 hours)
  Stream<List<AbsenceModel>> getRecentAbsenceNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.data()))
              .toList();

          // Sort by creation date (newest first)
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return absences;
        });
  }

  // Get recent general notifications (last 24 hours)
  Stream<List<Map<String, dynamic>>> getRecentGeneralNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('notifications')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
        });
  }

  // Get combined recent notifications count
  Stream<int> getRecentNotificationsCount() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    // For now, let's just use absence notifications as they are more reliable
    // We can expand this later when we have more notification data
    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          debugPrint('🔔 Recent absence notifications count: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Alternative method to get all recent notifications count
  Stream<int> getAllRecentNotificationsCount() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('absences')
        .where('source', isEqualTo: 'parent')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .asyncMap((absenceSnapshot) async {
          try {
            // Get general notifications count
            final notificationSnapshot = await _firestore
                .collection('notifications')
                .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
                .get();

            final totalCount = absenceSnapshot.docs.length + notificationSnapshot.docs.length;
            debugPrint('🔔 Total notifications count: $totalCount (Absences: ${absenceSnapshot.docs.length}, General: ${notificationSnapshot.docs.length})');
            return totalCount;
          } catch (e) {
            debugPrint('❌ Error getting notifications count: $e');
            return absenceSnapshot.docs.length; // Fallback to just absence count
          }
        });
  }

  // Get parent notifications count (for parent home screen)
  Stream<int> getParentNotificationsCount(String parentId) {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: parentId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          debugPrint('🔔 Parent notifications count for $parentId: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Get admin notifications count (for admin home screen)
  Stream<int> getAdminNotificationsCount() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    // Combine pending absences and recent notifications
    return _firestore
        .collection('absences')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          debugPrint('🔔 Admin notifications count (pending absences): ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Get all absences stream (for debugging)
  Stream<List<AbsenceModel>> getAllAbsencesStream() {
    return _firestore
        .collection('absences')
        .snapshots()
        .map((snapshot) {
          debugPrint('📊 All absences snapshot: ${snapshot.docs.length} documents');

          final absences = <AbsenceModel>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final absence = AbsenceModel.fromMap(data);
              absences.add(absence);
              debugPrint('📋 Found absence: ${absence.studentName} - ${absence.status.toString().split('.').last}');
            } catch (e) {
              debugPrint('❌ Error parsing absence ${doc.id}: $e');
            }
          }

          // Sort by creation date
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          debugPrint('✅ Returning ${absences.length} absences');
          return absences;
        });
  }

  // Debug function to check absences statistics
  Future<void> debugAllAbsences() async {
    try {
      debugPrint('🔍 === Absence Statistics ===');

      final snapshot = await _firestore.collection('absences').get();
      debugPrint('📊 Total absences: ${snapshot.docs.length}');

      // Count by status
      final pendingCount = snapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final approvedCount = snapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
      final rejectedCount = snapshot.docs.where((doc) => doc.data()['status'] == 'rejected').length;

      debugPrint('⏳ Pending: $pendingCount');
      debugPrint('✅ Approved: $approvedCount');
      debugPrint('❌ Rejected: $rejectedCount');

    } catch (e) {
      debugPrint('❌ Error getting absence statistics: $e');
    }
  }

  // Approve absence
  Future<void> approveAbsence(String absenceId, String approvedBy) async {
    try {
      debugPrint('🔄 Approving absence: $absenceId by $approvedBy');

      await _firestore.collection('absences').doc(absenceId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Absence approved successfully: $absenceId');
    } catch (e) {
      debugPrint('❌ Error approving absence: $e');
      throw Exception('فشل في الموافقة على الغياب: $e');
    }
  }

  // Reject absence
  Future<void> rejectAbsence(String absenceId, String rejectedBy, String reason) async {
    try {
      await _firestore.collection('absences').doc(absenceId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': Timestamp.now(),
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ Absence rejected successfully');
    } catch (e) {
      debugPrint('❌ Error rejecting absence: $e');
      throw Exception('فشل في رفض الغياب: $e');
    }
  }

  // Update absence status (generic method)
  Future<void> updateAbsenceStatus(String absenceId, AbsenceStatus status, String userId) async {
    try {
      debugPrint('🔄 Updating absence status: $absenceId to ${status.toString().split('.').last}');

      await _firestore.collection('absences').doc(absenceId).update({
        'status': status.toString().split('.').last,
        'approvedBy': userId,
        'approvedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Absence status updated successfully: $absenceId');
    } catch (e) {
      debugPrint('❌ Error updating absence status: $e');
      throw Exception('فشل في تحديث حالة الغياب: $e');
    }
  }

  // Get absence statistics
  Future<Map<String, int>> getAbsenceStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection('absences');

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final absences = snapshot.docs.map((doc) => AbsenceModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

      return {
        'total': absences.length,
        'pending': absences.where((a) => a.status == AbsenceStatus.pending).length,
        'approved': absences.where((a) => a.status == AbsenceStatus.approved).length,
        'rejected': absences.where((a) => a.status == AbsenceStatus.rejected).length,
        'sick': absences.where((a) => a.type == AbsenceType.sick).length,
        'family': absences.where((a) => a.type == AbsenceType.family).length,
        'travel': absences.where((a) => a.type == AbsenceType.travel).length,
        'emergency': absences.where((a) => a.type == AbsenceType.emergency).length,
        'other': absences.where((a) => a.type == AbsenceType.other).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting absence statistics: $e');
      return {};
    }
  }



  // ==================== USER MANAGEMENT ====================

  // Get all supervisors
  Future<List<UserModel>> getAllSupervisors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'supervisor')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting supervisors: $e');
      return [];
    }
  }

  // Get all admins
  Future<List<UserModel>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  // Survey Collection Methods

  /// Create new survey
  Future<String> createSurvey(SurveyModel survey) async {
    try {
      final surveyId = survey.id.isNotEmpty ? survey.id : _uuid.v4();
      final surveyWithId = survey.copyWith(id: surveyId);

      await _firestore
          .collection('surveys')
          .doc(surveyId)
          .set(surveyWithId.toMap());

      debugPrint('✅ Survey created successfully: $surveyId');
      return surveyId;
    } catch (e) {
      debugPrint('❌ Error creating survey: $e');
      rethrow;
    }
  }

  /// Get all surveys
  Stream<List<SurveyModel>> getAllSurveys() {
    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyModel.fromMap(doc.data()))
            .toList());
  }

  /// Get surveys by type
  Stream<List<SurveyModel>> getSurveysByType(SurveyType type) {
    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyModel.fromMap(doc.data()))
            .toList());
  }

  /// Get active surveys for user type
  Stream<List<SurveyModel>> getActiveSurveysForUser(String userType) {
    SurveyType? targetType;
    switch (userType) {
      case 'parent':
        targetType = SurveyType.parentFeedback;
        break;
      case 'supervisor':
        targetType = SurveyType.supervisorMonthly;
        break;
      default:
        return Stream.value([]);
    }

    return _firestore
        .collection('surveys')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('type', isEqualTo: targetType.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyModel.fromMap(doc.data()))
            .where((survey) => !survey.isExpired)
            .toList());
  }

  /// Submit survey response
  Future<String> submitSurveyResponse(SurveyResponse response) async {
    try {
      final responseId = response.id.isNotEmpty ? response.id : _uuid.v4();
      final responseWithId = SurveyResponse(
        id: responseId,
        surveyId: response.surveyId,
        respondentId: response.respondentId,
        respondentName: response.respondentName,
        respondentType: response.respondentType,
        answers: response.answers,
        submittedAt: response.submittedAt,
        isComplete: response.isComplete,
      );

      await _firestore
          .collection('survey_responses')
          .doc(responseId)
          .set(responseWithId.toMap());

      debugPrint('✅ Survey response submitted successfully: $responseId');
      return responseId;
    } catch (e) {
      debugPrint('❌ Error submitting survey response: $e');
      rethrow;
    }
  }

  /// Get survey responses
  Stream<List<SurveyResponse>> getSurveyResponses(String surveyId) {
    return _firestore
        .collection('survey_responses')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SurveyResponse.fromMap(doc.data()))
            .toList());
  }

  /// Check if user has responded to survey
  Future<bool> hasUserRespondedToSurvey(String surveyId, String userId) async {
    try {
      final response = await _firestore
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .where('respondentId', isEqualTo: userId)
          .limit(1)
          .get();

      return response.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking survey response: $e');
      return false;
    }
  }

  /// Update survey status
  Future<void> updateSurveyStatus(String surveyId, SurveyStatus status) async {
    try {
      await _firestore
          .collection('surveys')
          .doc(surveyId)
          .update({
            'status': status.toString().split('.').last,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Survey status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating survey status: $e');
      rethrow;
    }
  }

  /// Get survey statistics
  Future<Map<String, dynamic>> getSurveyStatistics(String surveyId) async {
    try {
      final responses = await _firestore
          .collection('survey_responses')
          .where('surveyId', isEqualTo: surveyId)
          .get();

      final totalResponses = responses.docs.length;
      final responsesByType = <String, int>{};

      for (final doc in responses.docs) {
        final data = doc.data();
        final type = data['respondentType'] ?? 'unknown';
        responsesByType[type] = (responsesByType[type] ?? 0) + 1;
      }

      return {
        'totalResponses': totalResponses,
        'responsesByType': responsesByType,
        'lastResponseDate': responses.docs.isNotEmpty
            ? responses.docs.first.data()['submittedAt']
            : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting survey statistics: $e');
      return {
        'totalResponses': 0,
        'responsesByType': <String, int>{},
        'lastResponseDate': null,
      };
    }
  }

  // Supervisor Assignment Methods

  /// Create new supervisor assignment
  Future<String> createSupervisorAssignment(SupervisorAssignmentModel assignment) async {
    try {
      final assignmentId = assignment.id.isNotEmpty ? assignment.id : _uuid.v4();
      final assignmentWithId = assignment.copyWith(id: assignmentId);

      await _firestore
          .collection('supervisor_assignments')
          .doc(assignmentId)
          .set(assignmentWithId.toMap());

      debugPrint('✅ Supervisor assignment created successfully: $assignmentId');
      return assignmentId;
    } catch (e) {
      debugPrint('❌ Error creating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Get all supervisor assignments
  Stream<List<SupervisorAssignmentModel>> getAllSupervisorAssignments() {
    return _firestore
        .collection('supervisor_assignments')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Get active supervisor assignments
  Stream<List<SupervisorAssignmentModel>> getActiveSupervisorAssignments() {
    return _firestore
        .collection('supervisor_assignments')
        .where('status', isEqualTo: 'active')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Get assignments for specific supervisor
  Stream<List<SupervisorAssignmentModel>> getSupervisorAssignments(String supervisorId) {
    return _firestore
        .collection('supervisor_assignments')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'active')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Get assignments for specific bus
  Stream<List<SupervisorAssignmentModel>> getBusAssignments(String busId) {
    return _firestore
        .collection('supervisor_assignments')
        .where('busId', isEqualTo: busId)
        .where('status', isEqualTo: 'active')
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
            .toList());
  }

  /// Update supervisor assignment
  Future<void> updateSupervisorAssignment(SupervisorAssignmentModel assignment) async {
    try {
      await _firestore
          .collection('supervisor_assignments')
          .doc(assignment.id)
          .update(assignment.toMap());

      debugPrint('✅ Supervisor assignment updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Deactivate supervisor assignment
  Future<void> deactivateSupervisorAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('supervisor_assignments')
          .doc(assignmentId)
          .update({
            'status': 'inactive',
            'unassignedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Supervisor assignment deactivated successfully');
    } catch (e) {
      debugPrint('❌ Error deactivating supervisor assignment: $e');
      rethrow;
    }
  }

  /// Create emergency assignment (temporary supervisor change)
  Future<String> createEmergencyAssignment({
    required String busId,
    required String newSupervisorId,
    required String newSupervisorName,
    required String busPlateNumber,
    required TripDirection direction,
    required String assignedBy,
    required String assignedByName,
    String? notes,
  }) async {
    try {
      // First, deactivate current assignment for this bus
      final currentAssignments = await _firestore
          .collection('supervisor_assignments')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'active')
          .get();

      String? originalSupervisorId;
      for (final doc in currentAssignments.docs) {
        final data = doc.data();
        originalSupervisorId = data['supervisorId'];
        await doc.reference.update({
          'status': 'inactive',
          'unassignedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create new emergency assignment
      final emergencyAssignment = SupervisorAssignmentModel(
        id: _uuid.v4(),
        supervisorId: newSupervisorId,
        supervisorName: newSupervisorName,
        busId: busId,
        busPlateNumber: busPlateNumber,
        direction: direction,
        status: AssignmentStatus.emergency,
        assignedAt: DateTime.now(),
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        notes: notes,
        isEmergencyAssignment: true,
        originalSupervisorId: originalSupervisorId,
      );

      return await createSupervisorAssignment(emergencyAssignment);
    } catch (e) {
      debugPrint('❌ Error creating emergency assignment: $e');
      rethrow;
    }
  }

  /// Get assignment statistics
  Future<AssignmentStatistics> getAssignmentStatistics() async {
    try {
      final assignmentsSnapshot = await _firestore
          .collection('supervisor_assignments')
          .get();

      final busesSnapshot = await _firestore
          .collection('buses')
          .where('isActive', isEqualTo: true)
          .get();

      final assignments = assignmentsSnapshot.docs
          .map((doc) => SupervisorAssignmentModel.fromMap(doc.data()))
          .toList();

      final totalBuses = busesSnapshot.docs.length;
      final activeAssignments = assignments.where((a) => a.isActive).length;
      final emergencyAssignments = assignments.where((a) => a.isEmergency).length;
      final unassignedBuses = totalBuses - activeAssignments;

      final assignmentsByDirection = <String, int>{};
      for (final assignment in assignments.where((a) => a.isActive)) {
        final direction = assignment.directionDisplayName;
        assignmentsByDirection[direction] = (assignmentsByDirection[direction] ?? 0) + 1;
      }

      return AssignmentStatistics(
        totalAssignments: assignments.length,
        activeAssignments: activeAssignments,
        emergencyAssignments: emergencyAssignments,
        unassignedBuses: unassignedBuses,
        assignmentsByDirection: assignmentsByDirection,
      );
    } catch (e) {
      debugPrint('❌ Error getting assignment statistics: $e');
      return AssignmentStatistics.empty();
    }
  }

  /// Get all students with their absence data for comprehensive report
  Stream<List<Map<String, dynamic>>> getAllStudentsWithAbsenceData() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((studentsSnapshot) async {
      List<Map<String, dynamic>> studentsWithAbsences = [];

      for (final studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        // Get absences for this student
        final absencesSnapshot = await _firestore
            .collection('absences')
            .where('studentId', isEqualTo: studentDoc.id)
            .where('source', isEqualTo: 'parent')
            .orderBy('date', descending: true)
            .get();

        final absences = absencesSnapshot.docs
            .map((doc) => AbsenceModel.fromMap(doc.data()))
            .toList();

        studentsWithAbsences.add({
          'student': studentData,
          'absences': absences,
        });
      }

      // Sort by number of absences (descending)
      studentsWithAbsences.sort((a, b) {
        final aAbsences = (a['absences'] as List).length;
        final bAbsences = (b['absences'] as List).length;
        return bAbsences.compareTo(aAbsences);
      });

      return studentsWithAbsences;
    });
  }

  // Student Behavior Evaluation Methods

  /// Create or update behavior evaluation
  Future<void> saveBehaviorEvaluation(StudentBehaviorEvaluation evaluation) async {
    try {
      final evaluationId = evaluation.id.isEmpty
          ? _uuid.v4()
          : evaluation.id;

      final updatedEvaluation = evaluation.copyWith(
        id: evaluationId,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('behavior_evaluations')
          .doc(evaluationId)
          .set(updatedEvaluation.toMap());

      debugPrint('✅ Behavior evaluation saved successfully: ${evaluation.studentName}');
    } catch (e) {
      debugPrint('❌ Error saving behavior evaluation: $e');
      throw Exception('فشل في حفظ التقييم السلوكي: $e');
    }
  }

  /// Get behavior evaluations for a supervisor in a specific month/year
  Future<List<StudentBehaviorEvaluation>> getBehaviorEvaluations({
    required String supervisorId,
    required int month,
    required int year,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('behavior_evaluations')
          .where('supervisorId', isEqualTo: supervisorId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      return snapshot.docs
          .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting behavior evaluations: $e');
      return [];
    }
  }

  /// Get behavior evaluations for a specific student
  Future<List<StudentBehaviorEvaluation>> getStudentBehaviorEvaluations(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('behavior_evaluations')
          .where('studentId', isEqualTo: studentId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student behavior evaluations: $e');
      return [];
    }
  }

  /// Get all behavior evaluations (for admin)
  Stream<List<StudentBehaviorEvaluation>> getAllBehaviorEvaluationsStream() {
    return _firestore
        .collection('behavior_evaluations')
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .orderBy('studentName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentBehaviorEvaluation.fromMap(doc.data()))
            .toList());
  }

  /// Delete behavior evaluation
  Future<void> deleteBehaviorEvaluation(String evaluationId) async {
    try {
      await _firestore
          .collection('behavior_evaluations')
          .doc(evaluationId)
          .delete();

      debugPrint('✅ Behavior evaluation deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting behavior evaluation: $e');
      throw Exception('فشل في حذف التقييم السلوكي: $e');
    }
  }
}
