import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/base64_image_widget.dart';


class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StudentStatus? _selectedStatus;
  String? _selectedGrade;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filters
          _buildFilters(),

          // Students List
          Expanded(
            child: _buildStudentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: const Color(0xFF1E88E5),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة طالب',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن طالب...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFF1E88E5)),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StudentStatus?>(
                  value: _selectedStatus,
                  hint: const Text('الحالة'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<StudentStatus?>(
                      value: null,
                      child: Text('جميع الحالات'),
                    ),
                    DropdownMenuItem<StudentStatus?>(
                      value: StudentStatus.home,
                      child: Row(
                        children: [
                          Icon(Icons.home, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('في المنزل'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<StudentStatus?>(
                      value: StudentStatus.onBus,
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('في الباص'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<StudentStatus?>(
                      value: StudentStatus.atSchool,
                      child: Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('في المدرسة'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Grade Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedGrade,
                  hint: const Text('الصف'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('جميع الصفوف'),
                    ),
                    ...['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس']
                        .map((grade) => DropdownMenuItem<String?>(
                              value: grade,
                              child: Text('الصف $grade'),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Clear Filters Button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedGrade = null;
                });
              },
              icon: const Icon(Icons.clear_all),
              tooltip: 'مسح الفلاتر',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
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
                Text('خطأ: ${snapshot.error}'),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () => setState(() {}),
                  width: 200,
                ),
              ],
            ),
          );
        }

        final allStudents = snapshot.data ?? [];
        final filteredStudents = allStudents.where((student) {
          // Search filter
          bool matchesSearch = _searchQuery.isEmpty ||
              student.name.toLowerCase().contains(_searchQuery) ||
              student.grade.toLowerCase().contains(_searchQuery) ||
              student.parentName.toLowerCase().contains(_searchQuery);

          // Status filter
          bool matchesStatus = _selectedStatus == null ||
              student.currentStatus == _selectedStatus;

          // Grade filter
          bool matchesGrade = _selectedGrade == null ||
              student.grade.contains(_selectedGrade!);

          return matchesSearch && matchesStatus && matchesGrade;
        }).toList();

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty ? Icons.school : Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'لا يوجد طلاب مسجلين'
                      : 'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'اضغط على زر إضافة طالب لبدء التسجيل'
                      : 'جرب البحث بكلمات مختلفة',
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            final student = filteredStudents[index];
            return _buildStudentCard(student);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatarWidget(
                imageUrl: student.photoUrl,
                studentName: student.name,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'الصف: ${student.grade}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(student.currentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.person, 'ولي الأمر', student.parentName),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.phone, 'الهاتف', student.parentPhone),
                    const SizedBox(height: 4),
                    _buildBusInfoRow(student),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.qr_code, 'رمز QR', student.qrCode),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'عرض',
                  onPressed: () => _showStudentDetails(student),
                  backgroundColor: Colors.green[50],
                  textColor: Colors.green,
                  height: 32,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'تعديل',
                  onPressed: () => _showEditStudentDialog(student),
                  backgroundColor: Colors.blue[50],
                  textColor: Colors.blue,
                  height: 32,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'حذف',
                  onPressed: () => _showDeleteConfirmation(student),
                  backgroundColor: Colors.red[50],
                  textColor: Colors.red,
                  height: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfoRow(StudentModel student) {
    if (student.busId.isEmpty) {
      return Row(
        children: [
          Icon(Icons.directions_bus_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'السيارة: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              'لم يتم تعيين سيارة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[600],
              ),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<BusModel?>(
      future: _databaseService.getBus(student.busId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Icon(Icons.directions_bus, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'السيارة: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
            ],
          );
        }

        final bus = snapshot.data;
        if (bus == null) {
          return Row(
            children: [
              Icon(Icons.directions_bus_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'السيارة: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  'سيارة غير موجودة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Icon(Icons.directions_bus, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'السيارة: ',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                '${bus.plateNumber} - ${bus.driverName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = Colors.green.withAlpha(25);
        textColor = Colors.green;
        icon = Icons.home;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange;
        icon = Icons.directions_bus;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue;
        icon = Icons.school;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    context.push('/admin/students/add');
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1E88E5),
              child: Text(
                student.name.isNotEmpty ? student.name[0] : 'ط',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('معرف الطالب', student.id),
              _buildDetailRow('الصف الدراسي', student.grade),
              _buildDetailRow('اسم المدرسة', student.schoolName),
              _buildDetailRow('ولي الأمر', student.parentName),
              _buildDetailRow('رقم الهاتف', student.parentPhone),
              _buildDetailRow('رمز QR', student.qrCode),
              _buildDetailRow('تاريخ التسجيل', _formatDate(student.createdAt)),
              _buildDetailRow('آخر تحديث', _formatDate(student.updatedAt)),
              if (student.busId.isNotEmpty) ...[
                const Divider(),
                FutureBuilder<BusModel?>(
                  future: _databaseService.getBus(student.busId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bus = snapshot.data;
                    if (bus == null) {
                      return _buildDetailRow('السيارة', 'غير موجودة');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات السيارة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('رقم اللوحة', bus.plateNumber),
                        _buildDetailRow('السائق', bus.driverName),
                        _buildDetailRow('رقم السائق', bus.driverPhone),
                        _buildDetailRow('خط السير', bus.route),
                        _buildDetailRow('السعة', '${bus.capacity} راكب'),
                        _buildDetailRow('التكييف', bus.hasAirConditioning ? 'مكيفة' : 'غير مكيفة'),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditStudentDialog(student);
            },
            child: const Text('تعديل'),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditStudentDialog(StudentModel student) {
    context.push('/admin/students/edit/${student.id}');
  }

  void _showDeleteConfirmation(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطالب: ${student.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStudent(student);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    try {
      await _databaseService.deleteStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الطالب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الطالب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


