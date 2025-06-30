import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../models/absence_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class RouteStatisticsScreen extends StatefulWidget {
  const RouteStatisticsScreen({super.key});

  @override
  State<RouteStatisticsScreen> createState() => _RouteStatisticsScreenState();
}

class _RouteStatisticsScreenState extends State<RouteStatisticsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  SupervisorAssignmentModel? _assignment;
  List<StudentModel> _students = [];
  List<AbsenceModel> _todayAbsences = [];
  List<AbsenceModel> _weekAbsences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final supervisorId = _authService.currentUser?.uid ?? '';
      final assignments = await _databaseService.getSupervisorAssignments(supervisorId).first;
      
      if (assignments.isNotEmpty) {
        _assignment = assignments.first;
        
        // تحميل الطلاب
        final students = await _databaseService.getStudentsByRoute(_assignment!.busRoute).first;
        
        // تحميل غيابات اليوم
        final todayAbsences = await _databaseService.getTodayAbsencesForSupervisor(supervisorId).first;
        
        // تحميل غيابات الأسبوع
        final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final weekAbsences = await _databaseService.getAbsencesInDateRange(
          supervisorId,
          weekStart,
          DateTime.now(),
        );
        
        setState(() {
          _students = students;
          _todayAbsences = todayAbsences;
          _weekAbsences = weekAbsences;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات خط السير',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_assignment != null)
              Text(
                _assignment!.busRoute,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1976D2),
                Color(0xFF1565C0),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignment == null
              ? _buildNoAssignmentState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRouteInfoCard(),
                        const SizedBox(height: 16),
                        _buildQuickStatsGrid(),
                        const SizedBox(height: 16),
                        _buildStudentStatusChart(),
                        const SizedBox(height: 16),
                        _buildAbsenceAnalysis(),
                        const SizedBox(height: 16),
                        _buildWeeklyTrends(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoAssignmentState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[100]!,
                    Colors.orange[50]!,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا يوجد تعيين نشط',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التواصل مع الإدارة لتعيينك على خط سير',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withAlpha(25),
            const Color(0xFF1976D2).withAlpha(25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5).withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات خط السير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _assignment!.busRoute,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.directions_bus,
                  'رقم الباص',
                  _assignment!.busPlateNumber,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.swap_horiz,
                  'الاتجاه',
                  _getDirectionText(_assignment!.direction),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'تاريخ التعيين',
                  DateFormat('yyyy/MM/dd').format(_assignment!.assignedAt),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.admin_panel_settings,
                  'تم التعيين بواسطة',
                  _assignment!.assignedByName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDirectionText(TripDirection direction) {
    switch (direction) {
      case TripDirection.toSchool:
        return 'ذهاب للمدرسة';
      case TripDirection.fromSchool:
        return 'عودة من المدرسة';
      case TripDirection.both:
        return 'ذهاب وعودة';
    }
  }

  Widget _buildQuickStatsGrid() {
    final activeStudents = _students.where((s) => s.isActive).length;
    final studentsOnBus = _students.where((s) => s.currentStatus == StudentStatus.onBus).length;
    final studentsAtSchool = _students.where((s) => s.currentStatus == StudentStatus.atSchool).length;
    final studentsAtHome = _students.where((s) => s.currentStatus == StudentStatus.home).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإحصائيات السريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي الطلاب',
                _students.length.toString(),
                Icons.group,
                const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'الطلاب النشطين',
                activeStudents.toString(),
                Icons.person_add_alt_1,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'في الباص',
                studentsOnBus.toString(),
                Icons.directions_bus,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'في المدرسة',
                studentsAtSchool.toString(),
                Icons.school,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
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
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatusChart() {
    final studentsOnBus = _students.where((s) => s.currentStatus == StudentStatus.onBus).length;
    final studentsAtSchool = _students.where((s) => s.currentStatus == StudentStatus.atSchool).length;
    final studentsAtHome = _students.where((s) => s.currentStatus == StudentStatus.home).length;
    final total = _students.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع الطلاب حسب الموقع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (total > 0) ...[
            _buildStatusBar('في المنزل', studentsAtHome, total, Colors.green),
            const SizedBox(height: 8),
            _buildStatusBar('في الباص', studentsOnBus, total, Colors.orange),
            const SizedBox(height: 8),
            _buildStatusBar('في المدرسة', studentsAtSchool, total, Colors.blue),
          ] else
            const Text(
              'لا يوجد طلاب في هذا الخط',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count من $total (${(percentage * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildAbsenceAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحليل الغيابات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAbsenceStatCard(
                  'غيابات اليوم',
                  _todayAbsences.length.toString(),
                  Icons.today,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAbsenceStatCard(
                  'غيابات الأسبوع',
                  _weekAbsences.length.toString(),
                  Icons.date_range,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الاتجاهات الأسبوعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'معدل الحضور',
            _calculateAttendanceRate(),
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTrendItem(
            'معدل الغياب',
            _calculateAbsenceRate(),
            Icons.trending_down,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateAttendanceRate() {
    if (_students.isEmpty) return '0%';
    final activeStudents = _students.where((s) => s.isActive).length;
    final attendanceRate = (activeStudents / _students.length) * 100;
    return '${attendanceRate.toInt()}%';
  }

  String _calculateAbsenceRate() {
    if (_students.isEmpty) return '0%';
    final weekAbsenceRate = (_weekAbsences.length / (_students.length * 7)) * 100;
    return '${weekAbsenceRate.toInt()}%';
  }
}
