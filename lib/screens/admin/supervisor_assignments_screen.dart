import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../models/user_model.dart';
import '../../models/bus_model.dart';

class SupervisorAssignmentsScreen extends StatefulWidget {
  const SupervisorAssignmentsScreen({super.key});

  @override
  State<SupervisorAssignmentsScreen> createState() => _SupervisorAssignmentsScreenState();
}

class _SupervisorAssignmentsScreenState extends State<SupervisorAssignmentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String _selectedFilter = 'all'; // all, active, emergency
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = UserModel.fromMap(userData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة تعيينات المشرفين',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateAssignmentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),
          
          // Filter Tabs
          _buildFilterTabs(),
          
          // Assignments List
          Expanded(
            child: _buildAssignmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return FutureBuilder<AssignmentStatistics>(
      future: _databaseService.getAssignmentStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? AssignmentStatistics.empty();
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E88E5), const Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withAlpha(76),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'إحصائيات التعيينات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('إجمالي التعيينات', stats.totalAssignments.toString(), Icons.assignment),
                  ),
                  Expanded(
                    child: _buildStatItem('التعيينات النشطة', stats.activeAssignments.toString(), Icons.check_circle),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('تعيينات الطوارئ', stats.emergencyAssignments.toString(), Icons.emergency),
                  ),
                  Expanded(
                    child: _buildStatItem('باصات غير مُعينة', stats.unassignedBuses.toString(), Icons.directions_bus_filled),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('all', 'الكل', Icons.list),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('active', 'النشطة', Icons.check_circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('emergency', 'الطوارئ', Icons.emergency),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1E88E5).withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return StreamBuilder<List<SupervisorAssignmentModel>>(
      stream: _getFilteredAssignments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تحميل التعيينات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _buildAssignmentCard(assignment);
          },
        );
      },
    );
  }

  Stream<List<SupervisorAssignmentModel>> _getFilteredAssignments() {
    switch (_selectedFilter) {
      case 'active':
        return _databaseService.getActiveSupervisorAssignments();
      case 'emergency':
        return _databaseService.getAllSupervisorAssignments()
            .map((assignments) => assignments.where((a) => a.isEmergency).toList());
      default:
        return _databaseService.getAllSupervisorAssignments();
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'active':
        message = 'لا توجد تعيينات نشطة حالياً';
        icon = Icons.check_circle_outline;
        break;
      case 'emergency':
        message = 'لا توجد تعيينات طوارئ حالياً';
        icon = Icons.emergency_outlined;
        break;
      default:
        message = 'لا توجد تعيينات مشرفين حالياً';
        icon = Icons.assignment_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة تعيين جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(SupervisorAssignmentModel assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: assignment.isEmergency
            ? Border.all(color: Colors.red.withAlpha(76), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(assignment.status),
                  color: _getStatusColor(assignment.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.supervisorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'باص ${assignment.busPlateNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assignment.statusDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(assignment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Assignment Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.schedule,
                  label: 'الاتجاه',
                  value: assignment.directionDisplayName,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'تاريخ التعيين',
                  value: _formatDate(assignment.assignedAt),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.person,
                  label: 'تم التعيين بواسطة',
                  value: assignment.assignedByName,
                ),
              ),
              if (assignment.isEmergency)
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.emergency,
                    label: 'نوع التعيين',
                    value: assignment.assignmentTypeDisplay,
                  ),
                ),
            ],
          ),

          if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملاحظات:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignment.notes!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              if (assignment.isActive) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEmergencyChangeDialog(assignment),
                    icon: const Icon(Icons.emergency, size: 16),
                    label: const Text('تغيير طوارئ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: assignment.isActive
                      ? () => _deactivateAssignment(assignment)
                      : null,
                  icon: Icon(
                    assignment.isActive ? Icons.stop : Icons.check,
                    size: 16,
                  ),
                  label: Text(assignment.isActive ? 'إنهاء التعيين' : 'منتهي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: assignment.isActive ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
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
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return Colors.green;
      case AssignmentStatus.emergency:
        return Colors.red;
      case AssignmentStatus.inactive:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.active:
        return Icons.check_circle;
      case AssignmentStatus.emergency:
        return Icons.emergency;
      case AssignmentStatus.inactive:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateAssignmentDialog() {
    // Implementation for creating new assignment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تعيين جديد'),
        content: const Text('سيتم تطوير هذه الميزة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyChangeDialog(SupervisorAssignmentModel assignment) {
    // Implementation for emergency supervisor change
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير مشرف الطوارئ'),
        content: const Text('سيتم تطوير هذه الميزة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAssignment(SupervisorAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إنهاء التعيين'),
        content: Text('هل أنت متأكد من إنهاء تعيين ${assignment.supervisorName} على باص ${assignment.busPlateNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء التعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deactivateSupervisorAssignment(assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنهاء التعيين بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في إنهاء التعيين: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
