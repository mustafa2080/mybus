import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/parent_student_link_model.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_bottom_navigation.dart';

class ParentStudentLinkingScreen extends StatefulWidget {
  const ParentStudentLinkingScreen({super.key});

  @override
  State<ParentStudentLinkingScreen> createState() => _ParentStudentLinkingScreenState();
}

class _ParentStudentLinkingScreenState extends State<ParentStudentLinkingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(
        title: 'ربط الطلاب بأولياء الأمور',
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Unlinked Students List
          Expanded(
            child: _buildUnlinkedStudentsList(),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'البحث عن طالب غير مربوط...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildUnlinkedStudentsList() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('لا يوجد طلاب'),
          );
        }

        // فلترة الطلاب غير المربوطين
        final allStudents = snapshot.data!;
        final unlinkedStudents = allStudents.where((student) {
          final matchesSearch = _searchQuery.isEmpty ||
              student.name.toLowerCase().contains(_searchQuery) ||
              student.parentName.toLowerCase().contains(_searchQuery) ||
              student.parentEmail.toLowerCase().contains(_searchQuery);
          
          // هنا يمكن إضافة منطق للتحقق من الطلاب غير المربوطين
          final isUnlinked = student.parentId.isEmpty || student.parentId.startsWith('parent_');
          
          return matchesSearch && isUnlinked;
        }).toList();

        if (unlinkedStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'جميع الطلاب مربوطون بأولياء أمورهم',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: unlinkedStudents.length,
          itemBuilder: (context, index) {
            final student = unlinkedStudents[index];
            return _buildStudentCard(student);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('ولي الأمر: ${student.parentName}'),
                      Text('الهاتف: ${student.parentPhone}'),
                      Text('البريد: ${student.parentEmail}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'غير مربوط',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showLinkDialog(student),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('ربط بولي أمر'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStudentDetails(student),
                    icon: const Icon(Icons.info, size: 18),
                    label: const Text('التفاصيل'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(StudentModel student) {
    final emailController = TextEditingController(text: student.parentEmail);
    final phoneController = TextEditingController(text: student.parentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ربط الطالب: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم إرسال رابط التفعيل لولي الأمر عبر البريد الإلكتروني والرسائل النصية',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _linkStudentToParent(student, emailController.text, phoneController.text);
            },
            child: const Text('إرسال رابط التفعيل'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطالب: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الاسم', student.name),
            _buildDetailRow('ولي الأمر', student.parentName),
            _buildDetailRow('الهاتف', student.parentPhone),
            _buildDetailRow('البريد', student.parentEmail),
            _buildDetailRow('المدرسة', student.schoolName),
            _buildDetailRow('الصف', student.grade),
            _buildDetailRow('العنوان', student.address),
            _buildDetailRow('خط الحافلة', student.busRoute),
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
      padding: const EdgeInsets.only(bottom: 8),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _linkStudentToParent(StudentModel student, String email, String phone) async {
    try {
      // إنشاء رابط تفعيل
      final linkId = 'link_${DateTime.now().millisecondsSinceEpoch}';
      
      final link = ParentStudentLinkModel(
        id: linkId,
        parentId: '',
        parentEmail: email,
        parentPhone: phone,
        studentIds: [student.id],
        isLinked: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ رابط التفعيل في قاعدة البيانات
      await _databaseService.createParentStudentLink(link);

      // محاكاة إرسال البريد الإلكتروني والرسائل النصية
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال رابط التفعيل إلى $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال رابط التفعيل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
