import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = true;
  UserModel? _currentUser;
  Map<String, dynamic> _schoolInfo = {};
  String _supervisorName = '';
  String _supervisorPhone = '';
  String _adminPhone = '';
  String _busAssignment = '';
  List<Map<String, String>> _studentsContacts = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      // Load current user info
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          _currentUser = UserModel.fromMap(userDoc.data()!);
          _supervisorName = _currentUser!.name;
          _supervisorPhone = _currentUser!.phone;
        }
      }

      // Load school information
      final schoolDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('school')
          .get();
      
      if (schoolDoc.exists) {
        _schoolInfo = schoolDoc.data() ?? {};
        _adminPhone = _schoolInfo['phone'] ?? '';
      }

      // Load bus assignment for supervisor
      await _loadBusAssignment();

      // Load students contacts for emergency
      await _loadStudentsContacts();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading emergency data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentsContacts() async {
    try {
      // Get students assigned to supervisor's bus
      // For now, get all students - this should be filtered by supervisor's bus assignment
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final contacts = <Map<String, String>>[];
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        if (data['parentPhone'] != null && data['parentPhone'].isNotEmpty) {
          contacts.add({
            'studentName': data['name'] ?? 'غير محدد',
            'parentName': data['parentName'] ?? 'غير محدد',
            'parentPhone': data['parentPhone'],
            'parentAddress': data['address'] ?? 'غير محدد',
            'grade': data['grade'] ?? 'غير محدد',
            'busRoute': data['busRoute'] ?? 'غير محدد',
          });
        }
      }

      // Sort by student name
      contacts.sort((a, b) => a['studentName']!.compareTo(b['studentName']!));
      _studentsContacts = contacts;
    } catch (e) {
      debugPrint('Error loading students contacts: $e');
    }
  }

  Future<void> _loadBusAssignment() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _busAssignment = 'غير محدد - لم يتم تسجيل الدخول';
        return;
      }

      // Get supervisor assignments
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('supervisor_assignments')
          .where('supervisorId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (assignmentsSnapshot.docs.isEmpty) {
        _busAssignment = 'لم يتم تعيين حافلة بعد';
        return;
      }

      // Get the first active assignment
      final assignmentData = assignmentsSnapshot.docs.first.data();
      final busId = assignmentData['busId'] as String?;
      final direction = assignmentData['direction'] as String?;

      if (busId != null) {
        // Get bus details
        final busDoc = await FirebaseFirestore.instance
            .collection('buses')
            .doc(busId)
            .get();

        if (busDoc.exists) {
          final busData = busDoc.data()!;
          final plateNumber = busData['plateNumber'] ?? 'غير محدد';
          final busType = busData['description'] ?? 'حافلة مدرسية';

          String directionText = '';
          switch (direction) {
            case 'toSchool':
              directionText = 'الذهاب للمدرسة';
              break;
            case 'fromSchool':
              directionText = 'العودة من المدرسة';
              break;
            case 'both':
              directionText = 'الذهاب والعودة';
              break;
            default:
              directionText = 'غير محدد';
          }

          _busAssignment = 'حافلة رقم: $plateNumber\nالنوع: $busType\nالاتجاه: $directionText';
        } else {
          _busAssignment = 'حافلة رقم: $busId (تفاصيل غير متوفرة)';
        }
      } else {
        _busAssignment = 'خطأ في بيانات التعيين';
      }
    } catch (e) {
      debugPrint('Error loading bus assignment: $e');
      _busAssignment = 'خطأ في تحميل بيانات التعيين';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'اتصال الطوارئ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Alert Card
                  _buildEmergencyAlertCard(),
                  const SizedBox(height: 20),

                  // Supervisor Info Card
                  _buildSupervisorInfoCard(),
                  const SizedBox(height: 20),

                  // Administration Contact Card
                  _buildAdminContactCard(),
                  const SizedBox(height: 20),

                  // Bus Assignment Card
                  _buildBusAssignmentCard(),
                  const SizedBox(height: 20),

                  // Students Parents Contacts Card
                  _buildStudentsContactsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmergencyAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'حالة طوارئ؟',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اتصل فوراً بالأرقام أدناه',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorInfoCard() {
    return _buildInfoCard(
      title: 'معلومات المشرفة',
      icon: Icons.person,
      color: Colors.blue,
      children: [
        _buildInfoRow(
          icon: Icons.badge,
          label: 'الاسم',
          value: _supervisorName.isNotEmpty ? _supervisorName : 'غير محدد',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'رقم الهاتف',
          value: _supervisorPhone.isNotEmpty ? _supervisorPhone : 'غير محدد',
          isClickable: _supervisorPhone.isNotEmpty,
          onTap: _supervisorPhone.isNotEmpty 
              ? () => _makePhoneCall(_supervisorPhone)
              : null,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.directions_bus,
          label: 'تسكين الباص',
          value: _busAssignment,
        ),
      ],
    );
  }

  Widget _buildAdminContactCard() {
    return _buildInfoCard(
      title: 'رقم الإدارة',
      icon: Icons.admin_panel_settings,
      color: Colors.green,
      children: [
        _buildInfoRow(
          icon: Icons.phone,
          label: 'رقم الإدارة',
          value: _adminPhone.isNotEmpty ? _adminPhone : 'غير محدد',
          isClickable: _adminPhone.isNotEmpty,
          onTap: _adminPhone.isNotEmpty 
              ? () => _makePhoneCall(_adminPhone)
              : null,
        ),
        if (_schoolInfo['email'] != null && _schoolInfo['email'].isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: 'البريد الإلكتروني',
            value: _schoolInfo['email'],
          ),
        ],
      ],
    );
  }

  Widget _buildBusAssignmentCard() {
    return _buildInfoCard(
      title: 'تسكين الحافلة',
      icon: Icons.directions_bus,
      color: Colors.orange,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withAlpha(76)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تفاصيل التعيين',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _busAssignment,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D3748),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (_busAssignment.contains('لم يتم تعيين') || _busAssignment.contains('خطأ')) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يرجى التواصل مع الإدارة لتحديد تعيين الحافلة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentsContactsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.contacts, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'أرقام أولياء الأمور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_studentsContacts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (_studentsContacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.contacts_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد معلومات اتصال متاحة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'البحث في جهات الاتصال...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contacts list
                    ..._studentsContacts.map((contact) => _buildContactCard(contact)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purple[100],
            child: Text(
              contact['studentName']!.isNotEmpty ? contact['studentName']![0] : 'ط',
              style: TextStyle(
                color: Colors.purple[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['studentName']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ولي الأمر: ${contact['parentName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'العنوان: ${contact['parentAddress']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (contact['grade'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الصف: ${contact['grade']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Phone number and call button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                contact['parentPhone']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _makePhoneCall(contact['parentPhone']!),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('اتصال'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isClickable ? Colors.blue.withAlpha(13) : Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: isClickable ? Border.all(color: Colors.blue.withAlpha(76)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isClickable ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isClickable ? Colors.blue : const Color(0xFF2D3748),
                ),
              ),
            ),
            if (isClickable)
              Icon(
                Icons.phone,
                size: 16,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
