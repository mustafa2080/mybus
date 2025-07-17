import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/trip_model.dart';
import '../../widgets/student_avatar.dart';

class StudentActivityScreen extends StatefulWidget {
  final String studentId;
  
  const StudentActivityScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentActivityScreen> createState() => _StudentActivityScreenState();
}

class _StudentActivityScreenState extends State<StudentActivityScreen> {
  final DatabaseService _databaseService = DatabaseService();
  StudentModel? _student;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 StudentActivityScreen initialized for student: ${widget.studentId}');
    _loadStudentData();
    _setupAutoRefresh();
  }

  // إعداد التحديث التلقائي كل دقيقة
  void _setupAutoRefresh() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // تحديث البيانات
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      debugPrint('🔍 Loading student data for ID: ${widget.studentId}');

      if (widget.studentId.isEmpty) {
        debugPrint('❌ Student ID is empty');
        return;
      }

      final student = await _databaseService.getStudent(widget.studentId);
      debugPrint('📚 Student data loaded: ${student?.name ?? 'null'}');

      if (mounted) {
        setState(() {
          _student = student;
        });

        // If student is still null after loading, show error
        if (student == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على بيانات الطالب'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading student data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Building StudentActivityScreen for student: ${widget.studentId}');

    // Validate student ID
    if (widget.studentId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('خطأ'),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'معرف الطالب غير صحيح',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('يرجى المحاولة مرة أخرى'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_student?.name ?? 'سجل الأنشطة'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SafeArea(
        child: _student == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل بيانات الطالب...'),
                ],
              ),
            )
          : Column(
              children: [
                // Student Info Card
                _buildStudentInfoCard(),

                // Date Filter
                _buildDateFilter(),

                // Quick Stats
                _buildQuickStats(),

                // Activities List
                Expanded(
                  child: _buildActivitiesList(),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    if (_student == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          StudentAvatar(
            photoUrl: _student!.photoUrl,
            studentName: _student!.name,
            radius: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _student!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الصف: ${_student!.grade}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'خط الباص: ${_student!.busRoute}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          _buildCurrentStatusChip(_student!.currentStatus),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green;
        icon = Icons.home;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange;
        icon = Icons.directions_bus;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue;
        icon = Icons.school;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _selectDate,
            child: const Text('تغيير التاريخ'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: StreamBuilder<List<TripModel>>(
        stream: _databaseService.getTripsByStudentAndDate(widget.studentId, _selectedDate),
        builder: (context, snapshot) {
          // Handle loading and error states
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Row(
              children: [
                Expanded(child: _buildStatCard('رحلات الصعود', '...', Icons.directions_bus, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('رحلات النزول', '...', Icons.home, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('إجمالي الرحلات', '...', Icons.timeline, const Color(0xFF1E88E5))),
              ],
            );
          }

          final studentTrips = snapshot.data ?? [];

          final boardingTrips = studentTrips
              .where((trip) => trip.action == TripAction.boardBus)
              .length;
          final leavingTrips = studentTrips
              .where((trip) => trip.action == TripAction.leaveBus)
              .length;

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'رحلات الصعود',
                  boardingTrips.toString(),
                  Icons.directions_bus,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'رحلات النزول',
                  leavingTrips.toString(),
                  Icons.home,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'إجمالي الرحلات',
                  studentTrips.length.toString(),
                  Icons.timeline,
                  const Color(0xFF1E88E5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color == Colors.green ? Colors.green.shade50 :
                     color == Colors.orange ? Colors.orange.shade50 :
                     Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'أنشطة اليوم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TripModel>>(
              future: _databaseService.getStudentTrips(widget.studentId, _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل السجل...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('خطأ: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Force rebuild to retry
                            });
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final studentTrips = snapshot.data ?? [];

                if (studentTrips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد أنشطة في هذا التاريخ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اختر تاريخاً آخر لعرض الأنشطة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: studentTrips.length,
                  itemBuilder: (context, index) {
                    final trip = studentTrips[index];
                    return _buildActivityItem(trip);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(TripModel trip) {
    final isBoarding = trip.action == TripAction.boardBus;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBoarding ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isBoarding ? Icons.directions_bus : Icons.home,
              color: isBoarding ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.actionDisplayText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.tripTypeDisplayText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ملاحظة: ${trip.notes}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.formattedTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'المشرف: ${trip.supervisorName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
