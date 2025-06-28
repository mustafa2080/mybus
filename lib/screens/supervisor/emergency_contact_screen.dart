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
      // This would be implemented when we add the supervisor-bus assignment system
      _busAssignment = 'سيتم تحديده من قبل الإدارة';

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
      // Get all students - in a real implementation, this would be filtered by supervisor's bus
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      final contacts = <Map<String, String>>[];
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        if (data['parentPhone'] != null && data['parentPhone'].isNotEmpty) {
          contacts.add({
            'studentName': data['name'] ?? 'غير محدد',
            'parentName': data['parentName'] ?? 'غير محدد',
            'parentPhone': data['parentPhone'],
          });
        }
      }

      _studentsContacts = contacts;
    } catch (e) {
      debugPrint('Error loading students contacts: $e');
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
                  const SizedBox(height: 20),

                  // Emergency Numbers Card
                  _buildEmergencyNumbersCard(),
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
      title: 'تسكين الباص',
      icon: Icons.directions_bus,
      color: Colors.orange,
      children: [
        _buildInfoRow(
          icon: Icons.info,
          label: 'الحالة',
          value: _busAssignment,
        ),
        const SizedBox(height: 8),
        const Text(
          'سيتم تحديد تسكين الباص من قبل الإدارة',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsContactsCard() {
    return _buildInfoCard(
      title: 'أرقام أولياء الأمور',
      icon: Icons.contacts,
      color: Colors.purple,
      children: [
        if (_studentsContacts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'لا توجد معلومات اتصال متاحة',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...(_studentsContacts.take(10).map((contact) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildInfoRow(
              icon: Icons.person,
              label: '${contact['studentName']} - ${contact['parentName']}',
              value: contact['parentPhone']!,
              isClickable: true,
              onTap: () => _makePhoneCall(contact['parentPhone']!),
            ),
          )).toList()),
        if (_studentsContacts.length > 10)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'وأرقام أخرى...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyNumbersCard() {
    return _buildInfoCard(
      title: 'أرقام الطوارئ العامة',
      icon: Icons.local_hospital,
      color: Colors.red,
      children: [
        _buildInfoRow(
          icon: Icons.local_hospital,
          label: 'الإسعاف',
          value: '997',
          isClickable: true,
          onTap: () => _makePhoneCall('997'),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.local_police,
          label: 'الشرطة',
          value: '999',
          isClickable: true,
          onTap: () => _makePhoneCall('999'),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.fire_truck,
          label: 'الإطفاء',
          value: '998',
          isClickable: true,
          onTap: () => _makePhoneCall('998'),
        ),
      ],
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
