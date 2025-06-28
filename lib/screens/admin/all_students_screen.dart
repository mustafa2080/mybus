import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _searchQuery = '';
  String _selectedGrade = 'الكل';
  String _selectedStatus = 'الكل';

  final List<String> _grades = [
    'الكل',
    ...AppConstants.studentGrades,
  ];

  final List<String> _statuses = [
    'الكل',
    'في المنزل',
    'في الباص',
    'في المدرسة'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('جميع الطلاب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/add-student'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث عن طالب...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        decoration: InputDecoration(
                          labelText: 'الصف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'الحالة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
              stream: _databaseService.getAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E88E5),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allStudents = snapshot.data ?? [];
                final filteredStudents = _filterStudents(allStudents);

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          allStudents.isEmpty ? 'لا يوجد طلاب مسجلين' : 'لا توجد نتائج للبحث',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (allStudents.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/admin/add-student'),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة طالب جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results Count
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'عدد النتائج: ${filteredStudents.length} من ${allStudents.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Students List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _buildStudentCard(student);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<StudentModel> _filterStudents(List<StudentModel> students) {
    return students.where((student) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.schoolName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.busRoute.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.parentName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by grade
      final matchesGrade = _selectedGrade == 'الكل' || student.grade == _selectedGrade;

      // Filter by status
      final matchesStatus = _selectedStatus == 'الكل' ||
          _getStatusText(student.currentStatus) == _selectedStatus;

      return matchesSearch && matchesGrade && matchesStatus;
    }).toList();
  }

  String _getStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';
    }
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.green;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.blue;
    }
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          radius: 25,
          child: Text(
            student.name.isNotEmpty ? student.name[0] : 'ط',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.school, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${student.schoolName} - ${student.grade}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'خط الباص: ${student.busRoute}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(student.currentStatus).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(student.currentStatus),
                style: TextStyle(
                  color: _getStatusColor(student.currentStatus),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey[700],
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                splashRadius: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                offset: const Offset(0, 40),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'عرض التفاصيل',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                          SizedBox(width: 12),
                          Text(
                            'تعديل البيانات',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'assign_bus',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_bus_outlined, size: 18, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'تسكين الباص',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'حذف الطالب',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onSelected: (String value) {
                  // Add a small delay to ensure the menu closes properly
                  Future.delayed(const Duration(milliseconds: 100), () {
                    switch (value) {
                      case 'edit':
                        context.push('/admin/students/edit/${student.id}');
                        break;
                      case 'assign_bus':
                        _showBusAssignmentDialog(student);
                        break;
                      case 'view':
                        _showStudentDetails(student);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(student);
                        break;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الاسم', student.name),
            _buildDetailRow('المدرسة', student.schoolName),
            _buildDetailRow('الصف', student.grade),
            _buildDetailRow('خط الباص', student.busRoute),
            _buildDetailRow('ولي الأمر', student.parentName),
            _buildDetailRow('هاتف ولي الأمر', student.parentPhone),
            _buildDetailRow('الحالة', _getStatusText(student.currentStatus)),
            _buildDetailRow('رمز QR', student.qrCode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب "${student.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _databaseService.deleteStudent(student.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الطالب بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف الطالب: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showBusAssignmentDialog(StudentModel student) {
    String? selectedBusId = student.busId.isNotEmpty ? student.busId : null;
    String selectedBusRoute = student.busRoute;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسكين الباص',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current assignment info
                if (student.busId.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(76)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الطالب مسكن حالياً في خط: ${student.busRoute}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'اختر الباص المناسب للطالب:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<BusModel>>(
                  stream: _databaseService.getAllBuses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('جاري تحميل الباصات...'),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'خطأ في تحميل الباصات: ${snapshot.error}',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final buses = snapshot.data?.where((bus) => bus.isActive).toList() ?? [];

                    if (buses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('لا توجد باصات نشطة متاحة'),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedBusId,
                      decoration: InputDecoration(
                        labelText: 'اختيار الباص',
                        hintText: 'اختر باص من القائمة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.directions_bus, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Text('بدون باص', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        ...buses.map((bus) {
                          return DropdownMenuItem<String>(
                            value: bus.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus.plateNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        bus.route,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedBusId = value;
                          if (value != null) {
                            final selectedBus = buses.firstWhere((bus) => bus.id == value);
                            selectedBusRoute = selectedBus.route;
                          } else {
                            selectedBusRoute = '';
                          }
                        });
                      },
                    );
                  },
                ),

                if (selectedBusId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.withAlpha(25), Colors.blue.withAlpha(51)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withAlpha(76)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.info,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'معلومات الباص المختار',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.route, 'خط السير', selectedBusRoute),
                        const SizedBox(height: 4),
                        FutureBuilder<BusModel?>(
                          future: _databaseService.getBus(selectedBusId!),
                          builder: (context, busSnapshot) {
                            if (busSnapshot.hasData) {
                              final bus = busSnapshot.data!;
                              return Column(
                                children: [
                                  _buildInfoRow(Icons.person, 'السائق', bus.driverName),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.people, 'السعة', '${bus.capacity} طالب'),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: selectedBusId != null || student.busId.isNotEmpty
                  ? () => _assignStudentToBus(student, selectedBusId, selectedBusRoute)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedBusId != null ? Icons.save : Icons.remove_circle,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedBusId != null ? 'حفظ التسكين' : 'إلغاء التسكين',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStudentToBus(StudentModel student, String? busId, String busRoute) async {
    // Close the assignment dialog first
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري حفظ التسكين...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {

      // Validate input data
      if (busId != null && busId.isEmpty) {
        throw Exception('معرف الباص غير صحيح');
      }

      if (busId != null && busRoute.isEmpty) {
        throw Exception('خط السير مطلوب عند اختيار باص');
      }

      // Create updated student with proper validation
      final updatedStudent = student.copyWith(
        busId: busId ?? '',
        busRoute: busRoute.trim(),
        updatedAt: DateTime.now(),
      );

      // Validate student data before update
      if (updatedStudent.id.isEmpty) {
        throw Exception('معرف الطالب مفقود');
      }

      // Update student in database
      await _databaseService.updateStudent(updatedStudent);

      // Close loading dialog and show success message
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  busId != null ? Icons.check_circle : Icons.remove_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    busId != null
                        ? 'تم تسكين ${student.name} في الباص بنجاح'
                        : 'تم إلغاء تسكين ${student.name} من الباص',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          );
        }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطأ في تحديث تسكين الباص: ${e.toString().replaceAll('Exception: ', '')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _assignStudentToBus(student, busId, busRoute),
            ),
          ),
        );
      }
    }

    // Helper method to build info rows with icon, label and value
    Widget _buildInfoRow(IconData icon, String label, String value) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 14,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }


