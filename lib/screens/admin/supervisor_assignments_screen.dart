import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../models/user_model.dart';
import '../../models/bus_model.dart';

// Statistics model for assignments
class AssignmentStatistics {
  final int totalAssignments;
  final int activeAssignments;
  final int emergencyAssignments;
  final int unassignedBuses;
  final int totalSupervisors;
  final int availableSupervisors;

  const AssignmentStatistics({
    required this.totalAssignments,
    required this.activeAssignments,
    required this.emergencyAssignments,
    required this.unassignedBuses,
    required this.totalSupervisors,
    required this.availableSupervisors,
  });

  factory AssignmentStatistics.empty() {
    return const AssignmentStatistics(
      totalAssignments: 0,
      activeAssignments: 0,
      emergencyAssignments: 0,
      unassignedBuses: 0,
      totalSupervisors: 0,
      availableSupervisors: 0,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDirectionText(TripDirection direction) {
    switch (direction) {
      case TripDirection.pickup:
        return 'الذهاب';
      case TripDirection.dropoff:
        return 'العودة';
      case TripDirection.both:
        return 'الذهاب والعودة';
    }
  }

  void _editAssignment(SupervisorAssignmentModel assignment) {
    _showEditAssignmentDialog(assignment);
  }

  void _deleteAssignment(SupervisorAssignmentModel assignment) {
    _showDeleteConfirmationDialog(assignment);
  }

  void _viewAssignmentDetails(SupervisorAssignmentModel assignment) {
    _showAssignmentDetailsDialog(assignment);
  }

  void _showEditAssignmentDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التعيين'),
        content: const Text('سيتم إضافة نافذة تعديل التعيين قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف تعيين ${assignment.supervisorName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.deleteSupervisorAssignment(assignment.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف التعيين بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف التعيين: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetailsDialog(SupervisorAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'تفاصيل التعيين',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('المشرف', assignment.supervisorName),
              _buildDetailRow('الباص', assignment.busId),
              _buildDetailRow('الاتجاه', _getDirectionText(assignment.direction)),
              _buildDetailRow('تاريخ التعيين', _formatDate(assignment.assignedAt)),
              _buildDetailRow('تم التعيين بواسطة', assignment.assignedBy),
              if (assignment.notes.isNotEmpty)
                _buildDetailRow('ملاحظات', assignment.notes),
              if (assignment.endDate != null)
                _buildDetailRow('تاريخ الانتهاء', _formatDate(assignment.endDate!)),
              _buildDetailRow('نوع التعيين', assignment.isEmergency ? 'طوارئ' : 'عادي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return FutureBuilder<Map<String, dynamic>>(
      future: _databaseService.getAssignmentStatistics(),
      builder: (context, snapshot) {
        final statsData = snapshot.data ?? {};
        final stats = AssignmentStatistics(
          totalAssignments: statsData['totalAssignments'] ?? 0,
          activeAssignments: statsData['activeAssignments'] ?? 0,
          emergencyAssignments: statsData['emergencyAssignments'] ?? 0,
          unassignedBuses: statsData['unassignedBuses'] ?? 0,
          totalSupervisors: statsData['totalSupervisors'] ?? 0,
          availableSupervisors: statsData['availableSupervisors'] ?? 0,
        );
        
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('إجمالي المشرفين', stats.totalSupervisors.toString(), Icons.supervisor_account),
                  ),
                  Expanded(
                    child: _buildStatItem('المشرفين المتاحين', stats.availableSupervisors.toString(), Icons.person_check),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: assignment.isEmergency
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: assignment.isEmergency
              ? LinearGradient(
                  colors: [Colors.red[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.blue[50]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: assignment.isEmergency ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          assignment.isEmergency ? Icons.emergency : Icons.assignment_turned_in,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.isEmergency ? 'طوارئ' : 'عادي',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'تم في ${_formatDate(assignment.assignedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main info section
              Row(
                children: [
                  // Bus info
                  Expanded(
                    flex: 2,
                    child: _buildInfoSection(
                      title: 'معلومات الباص',
                      icon: Icons.directions_bus,
                      color: Colors.blue,
                      children: [
                        _buildInfoRow('رقم الباص', assignment.busId),
                        FutureBuilder<BusModel?>(
                          future: _databaseService.getBusById(assignment.busId),
                          builder: (context, snapshot) {
                            final bus = snapshot.data;
                            return Column(
                              children: [
                                _buildInfoRow('رقم اللوحة', bus?.plateNumber ?? 'غير محدد'),
                                _buildInfoRow('الوصف', bus?.description ?? 'غير محدد'),
                                _buildInfoRow('السعة', bus != null ? '${bus.capacity} راكب' : 'غير محدد'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Supervisor info
                  Expanded(
                    flex: 2,
                    child: _buildInfoSection(
                      title: 'معلومات المشرف',
                      icon: Icons.supervisor_account,
                      color: Colors.green,
                      children: [
                        FutureBuilder<UserModel?>(
                          future: _databaseService.getUserById(assignment.supervisorId),
                          builder: (context, snapshot) {
                            final supervisor = snapshot.data;
                            return Column(
                              children: [
                                _buildInfoRow('الاسم', supervisor?.name ?? 'غير محدد'),
                                _buildInfoRow('الهاتف', supervisor?.phone ?? 'غير محدد'),
                                _buildInfoRow('الإيميل', supervisor?.email ?? 'غير محدد'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Assignment details
              _buildInfoSection(
                title: 'تفاصيل التعيين',
                icon: Icons.info,
                color: Colors.orange,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildInfoRow('الاتجاه', _getDirectionText(assignment.direction))),
                      Expanded(child: _buildInfoRow('تاريخ التعيين', _formatDate(assignment.assignedAt))),
                    ],
                  ),
                  if (assignment.notes.isNotEmpty)
                    _buildInfoRow('ملاحظات', assignment.notes),
                  Row(
                    children: [
                      Expanded(child: _buildInfoRow('تم التعيين بواسطة', assignment.assignedBy)),
                      if (assignment.endDate != null)
                        Expanded(child: _buildInfoRow('تاريخ الانتهاء', _formatDate(assignment.endDate!))),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editAssignment(assignment),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteAssignment(assignment),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewAssignmentDetails(assignment),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('تفاصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    showDialog(
      context: context,
      builder: (context) => _CreateAssignmentDialog(
        databaseService: _databaseService,
        currentUser: _currentUser,
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

class _CreateAssignmentDialog extends StatefulWidget {
  final DatabaseService databaseService;
  final UserModel? currentUser;

  const _CreateAssignmentDialog({
    required this.databaseService,
    this.currentUser,
  });

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  String? _selectedSupervisorId;
  String? _selectedBusId;
  TripDirection _selectedDirection = TripDirection.both;
  String _notes = '';
  bool _isLoading = false;

  List<UserModel> _supervisors = [];
  List<BusModel> _buses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load supervisors
      _supervisors = await widget.databaseService.getAllSupervisors();

      // Load buses
      _buses = await widget.databaseService.getAllBuses().first;

      setState(() => _isLoading = false);
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_add, color: Color(0xFF1E88E5)),
          SizedBox(width: 8),
          Text('إضافة تعيين جديد'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supervisor selection
                  DropdownButtonFormField<String>(
                    value: _selectedSupervisorId,
                    decoration: const InputDecoration(
                      labelText: 'اختر المشرف',
                      border: OutlineInputBorder(),
                    ),
                    items: _supervisors.map((supervisor) {
                      return DropdownMenuItem(
                        value: supervisor.id,
                        child: Text(supervisor.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSupervisorId = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bus selection
                  DropdownButtonFormField<String>(
                    value: _selectedBusId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الباص',
                      border: OutlineInputBorder(),
                    ),
                    items: _buses.map((bus) {
                      return DropdownMenuItem(
                        value: bus.id,
                        child: Text('${bus.plateNumber} - ${bus.route}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBusId = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Direction selection
                  DropdownButtonFormField<TripDirection>(
                    value: _selectedDirection,
                    decoration: const InputDecoration(
                      labelText: 'اتجاه الرحلة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TripDirection.toSchool,
                        child: Text('الذهاب للمدرسة'),
                      ),
                      DropdownMenuItem(
                        value: TripDirection.fromSchool,
                        child: Text('العودة من المدرسة'),
                      ),
                      DropdownMenuItem(
                        value: TripDirection.both,
                        child: Text('كلا الاتجاهين'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedDirection = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _notes = value,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _createAssignment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
          child: const Text('إنشاء التعيين'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedSupervisorId != null &&
           _selectedBusId != null &&
           !_isLoading;
  }

  Future<void> _createAssignment() async {
    if (!_canSubmit()) return;

    try {
      setState(() => _isLoading = true);

      final supervisor = _supervisors.firstWhere((s) => s.id == _selectedSupervisorId);
      final bus = _buses.firstWhere((b) => b.id == _selectedBusId);

      final assignmentId = widget.databaseService.generateTripId();
      final assignment = SupervisorAssignmentModel(
        id: assignmentId,
        supervisorId: _selectedSupervisorId!,
        supervisorName: supervisor.name,
        busId: _selectedBusId!,
        busPlateNumber: bus.plateNumber,
        direction: _selectedDirection,
        assignedAt: DateTime.now(),
        assignedBy: widget.currentUser?.id ?? '',
        assignedByName: widget.currentUser?.name ?? 'مدير',
        notes: _notes.isNotEmpty ? _notes : null,
      );

      await widget.databaseService.createSupervisorAssignment(assignment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء التعيين بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التعيين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
