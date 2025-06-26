import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';

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
    'الروضة',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر'
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
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'view',
                  child: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('عرض التفاصيل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/admin/students/edit/${student.id}');
                    break;
                  case 'view':
                    _showStudentDetails(student);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(student);
                    break;
                }
              },
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
}


