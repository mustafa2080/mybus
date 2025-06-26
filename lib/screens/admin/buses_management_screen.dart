import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/base64_image_widget.dart';

class BusesManagementScreen extends StatefulWidget {
  const BusesManagementScreen({super.key});

  @override
  State<BusesManagementScreen> createState() => _BusesManagementScreenState();
}

class _BusesManagementScreenState extends State<BusesManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _connectionTested = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      final isConnected = await _databaseService.testConnection();
      setState(() {
        _connectionTested = true;
      });

      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تحذير: مشكلة في الاتصال بقاعدة البيانات'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Connection test error: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Hide the default AppBar
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // Modern Header
            _buildModernHeader(),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withAlpha(76), // 0.3 * 255 = 76
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              // Header Row with better layout
              Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        debugPrint('🔙 Back button pressed - navigating to admin home');
                        try {
                          // Try go_router first
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            // Fallback: navigate to admin home
                            context.go('/admin');
                          }
                        } catch (e) {
                          debugPrint('❌ GoRouter navigation error: $e');
                          // Fallback to Navigator
                          try {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(context, '/admin');
                            }
                          } catch (navError) {
                            debugPrint('❌ Navigator fallback error: $navError');
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'العودة للصفحة الرئيسية',
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title with icon
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إدارة السيارات',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'إضافة وتعديل السيارات والسائقين',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Add Bus Button
                  Material(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: InkWell(
                      onTap: _showAddBusDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'إضافة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats Row
              _buildStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<List<BusModel>>(
      stream: _databaseService.getAllBuses(),
      builder: (context, busSnapshot) {
        if (!busSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final buses = busSnapshot.data!;
        return StreamBuilder<List<StudentModel>>(
          stream: _databaseService.getAllStudents(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final students = studentSnapshot.data!;
            final activeBuses = buses.where((bus) =>
              students.any((student) => student.busId == bus.id)
            ).length;

            final currentStudents = students.where((student) =>
              student.currentStatus == StudentStatus.onBus ||
              student.currentStatus == StudentStatus.atSchool
            ).length;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('إجمالي السيارات', buses.length.toString(), Icons.directions_bus, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatCard('السيارات النشطة', activeBuses.toString(), Icons.check_circle, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('الطلاب الحاليين', currentStudents.toString(), Icons.people, Colors.blue),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38), // 0.15 * 255 = 38
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(76), // 0.3 * 255 = 76
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        
        // Buses List
        Expanded(
          child: StreamBuilder<List<BusModel>>(
            stream: _databaseService.getAllBuses(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('❌ Error loading buses: ${snapshot.error}');
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
                        'تحقق من الاتصال بالإنترنت',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF9800),
                  ),
                );
              }

              final buses = snapshot.data ?? [];

              if (buses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد سيارات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'انقر على + لإضافة سيارة جديدة',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 :
                                 MediaQuery.of(context).size.width > 800 ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: buses.length,
                itemBuilder: (context, index) {
                  final bus = buses[index];
                  return _buildModernBusCard(bus);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernBusCard(BusModel bus) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20), // 0.08 * 255 = 20
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Bus Image Header
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Bus Image or Icon
                    Center(
                      child: bus.imageUrl != null && bus.imageUrl!.isNotEmpty
                          ? Base64ImageWidget(
                              imageUrl: bus.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: _buildBusIcon(),
                            )
                          : _buildBusIcon(),
                    ),

                    // Overlay gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(76), // 0.3 * 255 = 76
                          ],
                        ),
                      ),
                    ),

                    // Plate Number Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(229), // 0.9 * 255 = 229
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bus.plateNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ),

                    // AC Status
                    if (bus.hasAirConditioning)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(229), // 0.9 * 255 = 229
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.ac_unit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bus Info Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bus Description
                    Text(
                      bus.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Students Count
                    _buildCompactStudentsCount(bus),
                    const SizedBox(height: 8),

                    // Driver Info
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bus.driverName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Route Info
                    Row(
                      children: [
                        Icon(Icons.route, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bus.route,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.people,
                            label: 'الطلاب',
                            color: const Color(0xFF667EEA),
                            onPressed: () => _showBusStudentsDialog(bus),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit,
                            label: 'تعديل',
                            color: const Color(0xFFFF9800),
                            onPressed: () => _showEditBusDialog(bus),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: '',
                          color: Colors.red,
                          onPressed: () => _showDeleteConfirmation(bus),
                          isIconOnly: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Icon(
        Icons.directions_bus,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildCompactStudentsCount(BusModel bus) {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getStudentsByBusId(bus.id),
      builder: (context, snapshot) {
        debugPrint('🚌 Loading students for bus: ${bus.id} (${bus.plateNumber})');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withAlpha(25), // 0.1 * 255 = 25
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'تحميل...',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ Error loading students for bus ${bus.id}: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 10, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  'خطأ',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final students = snapshot.data ?? [];
        debugPrint('📊 Found ${students.length} students for bus ${bus.plateNumber}');

        final currentStudents = students.where((student) =>
          student.currentStatus == StudentStatus.onBus ||
          student.currentStatus == StudentStatus.atSchool
        ).toList();

        final totalStudents = students.length;
        final currentCount = currentStudents.length;

        debugPrint('📈 Bus ${bus.plateNumber}: $currentCount/$totalStudents students');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: currentCount > 0 ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: currentCount > 0 ? Colors.green.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people,
                size: 12,
                color: currentCount > 0 ? Colors.green.shade700 : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '$currentCount/$totalStudents',
                style: TextStyle(
                  color: currentCount > 0 ? Colors.green.shade700 : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isIconOnly = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isIconOnly ? 8 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(25), // 0.1 * 255 = 25
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withAlpha(76), // 0.3 * 255 = 76
            ),
          ),
          child: isIconOnly
              ? Icon(icon, size: 16, color: color)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: color),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }



  void _showBusStudentsDialog(BusModel bus) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلاب السيارة ${bus.plateNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'السائق: ${bus.driverName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {}); // Refresh data
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث البيانات'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث البيانات',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Students List
              Expanded(
                child: StreamBuilder<List<StudentModel>>(
                  stream: _databaseService.getStudentsByBusId(bus.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF9800),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint('❌ Dialog Error loading students for bus ${bus.id}: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            const Text('خطأ في تحميل البيانات'),
                            const SizedBox(height: 8),
                            Text(
                              'Bus ID: ${bus.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {}); // Trigger rebuild
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final students = snapshot.data ?? [];
                    debugPrint('🚌 Dialog: Found ${students.length} students for bus ${bus.plateNumber}');

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد طلاب في هذه السيارة',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bus ID: ${bus.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'لإضافة طلاب لهذه السيارة:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '1. اذهب لإدارة الطلاب\n2. اختر طالب\n3. عدل بياناته\n4. اختر هذه السيارة',
                                    style: TextStyle(fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group students by status
                    final currentStudents = students.where((student) =>
                      student.currentStatus == StudentStatus.onBus ||
                      student.currentStatus == StudentStatus.atSchool
                    ).toList();

                    final homeStudents = students.where((student) =>
                      student.currentStatus == StudentStatus.home
                    ).toList();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary
                          _buildStudentsSummary(students.length, currentStudents.length),
                          const SizedBox(height: 20),

                          // Current Students (On Bus/At School)
                          if (currentStudents.isNotEmpty) ...[
                            _buildSectionHeader(
                              'الطلاب الحاليين (${currentStudents.length})',
                              Icons.directions_bus,
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            ...currentStudents.map((student) => _buildStudentCard(student, true)),
                            const SizedBox(height: 20),
                          ],

                          // Students at Home
                          if (homeStudents.isNotEmpty) ...[
                            _buildSectionHeader(
                              'الطلاب في المنزل (${homeStudents.length})',
                              Icons.home,
                              Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            ...homeStudents.map((student) => _buildStudentCard(student, false)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsSummary(int totalStudents, int currentStudents) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص الطلاب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildSummaryItem('المجموع', totalStudents.toString(), Colors.blue),
                    const SizedBox(width: 16),
                    _buildSummaryItem('الحاليين', currentStudents.toString(), Colors.green),
                    const SizedBox(width: 16),
                    _buildSummaryItem('في المنزل', (totalStudents - currentStudents).toString(), Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withAlpha(178), // 0.7 * 255 = 178
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25), // 0.1 * 255 = 25
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(StudentModel student, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Student Avatar
          StudentAvatarWidget(
            imageUrl: student.photoUrl,
            studentName: student.name,
            radius: 20,
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.grade} - ${student.schoolName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ولي الأمر: ${student.parentName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(student.currentStatus).withAlpha(25), // 0.1 * 255 = 25
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(student.currentStatus).withAlpha(76), // 0.3 * 255 = 76
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(student.currentStatus),
                  size: 12,
                  color: _getStatusColor(student.currentStatus),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(student.currentStatus),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(student.currentStatus),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.grey;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Icons.home;
      case StudentStatus.onBus:
        return Icons.directions_bus;
      case StudentStatus.atSchool:
        return Icons.school;
    }
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

  void _showAddBusDialog() {
    final plateNumberController = TextEditingController();
    final descriptionController = TextEditingController();
    final driverNameController = TextEditingController();
    final driverPhoneController = TextEditingController();
    final routeController = TextEditingController();
    final capacityController = TextEditingController(text: '30');
    bool hasAirConditioning = false;
    String? selectedImageBase64;
    final formKey = GlobalKey<FormState>();
    final ImagePicker imagePicker = ImagePicker();
    final StorageService storageService = StorageService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة سيارة جديدة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال رقم اللوحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف السيارة',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال وصف السيارة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم السائق',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم السائق';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: driverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف السائق',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال رقم الهاتف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: 'خط السير',
                      prefixIcon: Icon(Icons.route),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال خط السير';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'سعة السيارة',
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال سعة السيارة';
                      }
                      final capacity = int.tryParse(value);
                      if (capacity == null || capacity <= 0) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('مكيفة'),
                    value: hasAirConditioning,
                    onChanged: (value) {
                      setDialogState(() {
                        hasAirConditioning = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  // Bus Image Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'صورة السيارة (اختياري)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Image Preview
                        if (selectedImageBase64 != null)
                          Container(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Base64ImageWidget(
                                imageUrl: selectedImageBase64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                        // Image Picker Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final XFile? image = await imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 800,
                                      maxHeight: 600,
                                      imageQuality: 80,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      final compressedBytes = storageService.compressStudentImage(bytes);
                                      final base64String = base64Encode(compressedBytes);

                                      setDialogState(() {
                                        selectedImageBase64 = 'data:image/jpeg;base64,$base64String';
                                      });
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Error picking image: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('خطأ في اختيار الصورة'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('من المعرض'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final XFile? image = await imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 800,
                                      maxHeight: 600,
                                      imageQuality: 80,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      final compressedBytes = storageService.compressStudentImage(bytes);
                                      final base64String = base64Encode(compressedBytes);

                                      setDialogState(() {
                                        selectedImageBase64 = 'data:image/jpeg;base64,$base64String';
                                      });
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Error taking photo: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('خطأ في التقاط الصورة'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('كاميرا'),
                              ),
                            ),
                          ],
                        ),

                        if (selectedImageBase64 != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                selectedImageBase64 = null;
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'حذف الصورة',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (formKey.currentState!.validate()) {
                  await _addBus(
                    plateNumberController.text.trim(),
                    descriptionController.text.trim(),
                    driverNameController.text.trim(),
                    driverPhoneController.text.trim(),
                    routeController.text.trim(),
                    int.parse(capacityController.text.trim()),
                    hasAirConditioning,
                    selectedImageBase64,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBus(
    String plateNumber,
    String description,
    String driverName,
    String driverPhone,
    String route,
    int capacity,
    bool hasAirConditioning,
    String? imageUrl,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚌 Creating new bus with data:');
      debugPrint('  - Plate Number: $plateNumber');
      debugPrint('  - Description: $description');
      debugPrint('  - Driver Name: $driverName');
      debugPrint('  - Driver Phone: $driverPhone');
      debugPrint('  - Route: $route');
      debugPrint('  - Capacity: $capacity');
      debugPrint('  - Has AC: $hasAirConditioning');

      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔐 Current user: ${user?.email ?? 'Not authenticated'}');

      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final busId = _databaseService.generateBusId();
      debugPrint('  - Generated ID: $busId');

      final bus = BusModel(
        id: busId,
        plateNumber: plateNumber,
        description: description,
        driverName: driverName,
        driverPhone: driverPhone,
        route: route,
        capacity: capacity,
        hasAirConditioning: hasAirConditioning,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('🔄 Adding bus to database...');
      await _databaseService.addBus(bus);
      debugPrint('✅ Bus added successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة السيارة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding bus: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة السيارة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEditBusDialog(BusModel bus) {
    final plateNumberController = TextEditingController(text: bus.plateNumber);
    final descriptionController = TextEditingController(text: bus.description);
    final driverNameController = TextEditingController(text: bus.driverName);
    final driverPhoneController = TextEditingController(text: bus.driverPhone);
    final routeController = TextEditingController(text: bus.route);
    final capacityController = TextEditingController(text: bus.capacity.toString());
    bool hasAirConditioning = bus.hasAirConditioning;
    String? selectedImageBase64 = bus.imageUrl; // Current image
    final formKey = GlobalKey<FormState>();
    final ImagePicker imagePicker = ImagePicker();
    final StorageService storageService = StorageService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل السيارة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال رقم اللوحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف السيارة',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال وصف السيارة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم السائق',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم السائق';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: driverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف السائق',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال رقم الهاتف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: 'خط السير',
                      prefixIcon: Icon(Icons.route),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال خط السير';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'سعة السيارة',
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال سعة السيارة';
                      }
                      final capacity = int.tryParse(value);
                      if (capacity == null || capacity <= 0) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('مكيفة'),
                    value: hasAirConditioning,
                    onChanged: (value) {
                      setDialogState(() {
                        hasAirConditioning = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  // Bus Image Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'صورة السيارة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Current/Selected Image Preview
                        if (selectedImageBase64 != null && selectedImageBase64!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Base64ImageWidget(
                                imageUrl: selectedImageBase64,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.directions_bus, size: 40),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Image Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final XFile? image = await imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 800,
                                      maxHeight: 600,
                                      imageQuality: 80,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      final compressedBytes = storageService.compressStudentImage(bytes);
                                      final base64String = base64Encode(compressedBytes);

                                      setDialogState(() {
                                        selectedImageBase64 = 'data:image/jpeg;base64,$base64String';
                                      });

                                      debugPrint('✅ Image selected and compressed: ${compressedBytes.length} bytes');
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Error picking image: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('خطأ في اختيار الصورة'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('من المعرض'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final XFile? image = await imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 800,
                                      maxHeight: 600,
                                      imageQuality: 80,
                                    );

                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      final compressedBytes = storageService.compressStudentImage(bytes);
                                      final base64String = base64Encode(compressedBytes);

                                      setDialogState(() {
                                        selectedImageBase64 = 'data:image/jpeg;base64,$base64String';
                                      });

                                      debugPrint('✅ Photo taken and compressed: ${compressedBytes.length} bytes');
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Error taking photo: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('خطأ في التقاط الصورة'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('كاميرا'),
                              ),
                            ),
                          ],
                        ),

                        if (selectedImageBase64 != null && selectedImageBase64!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    selectedImageBase64 = null;
                                  });
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(
                                  'حذف الصورة',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              const Spacer(),
                              if (selectedImageBase64 != bus.imageUrl)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info, size: 14, color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'صورة جديدة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _updateBus(
                    bus,
                    plateNumberController.text.trim(),
                    descriptionController.text.trim(),
                    driverNameController.text.trim(),
                    driverPhoneController.text.trim(),
                    routeController.text.trim(),
                    int.parse(capacityController.text.trim()),
                    hasAirConditioning,
                    selectedImageBase64,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBus(
    BusModel originalBus,
    String plateNumber,
    String description,
    String driverName,
    String driverPhone,
    String route,
    int capacity,
    bool hasAirConditioning,
    String? imageUrl,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedBus = originalBus.copyWith(
        plateNumber: plateNumber,
        description: description,
        driverName: driverName,
        driverPhone: driverPhone,
        route: route,
        capacity: capacity,
        hasAirConditioning: hasAirConditioning,
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateBus(updatedBus);

      if (mounted) {
        String message = 'تم تحديث السيارة بنجاح';
        if (imageUrl != null && imageUrl != originalBus.imageUrl) {
          message += ' مع صورة جديدة مضغوطة';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(BusModel bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف السيارة "${bus.plateNumber}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteBus(bus.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBus(String busId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteBus(busId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف السيارة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
