import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../models/bus_model.dart';

class BusesManagementScreen extends StatefulWidget {
  const BusesManagementScreen({super.key});

  @override
  State<BusesManagementScreen> createState() => _BusesManagementScreenState();
}

class _BusesManagementScreenState extends State<BusesManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة السيارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBusDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'البحث عن سيارة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Buses List
          Expanded(
            child: StreamBuilder<List<BusModel>>(
              stream: _databaseService.getAllBuses(),
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
                        Text('خطأ في تحميل السيارات: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final buses = snapshot.data ?? [];
                final filteredBuses = buses.where((bus) {
                  return bus.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         bus.driverName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         bus.route.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredBuses.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    return _buildBusCard(bus);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'لا توجد سيارات مسجلة' : 'لا توجد نتائج للبحث',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على + لإضافة سيارة جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusModel bus) {
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
        border: !bus.isActive 
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
                  color: bus.isActive 
                      ? const Color(0xFF4CAF50).withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: bus.isActive ? const Color(0xFF4CAF50) : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.plateNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bus.route,
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
                  color: bus.isActive 
                      ? const Color(0xFF4CAF50).withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bus.isActive ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontSize: 12,
                    color: bus.isActive ? const Color(0xFF4CAF50) : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bus Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.person,
                  label: 'السائق',
                  value: bus.driverName,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.phone,
                  label: 'الهاتف',
                  value: bus.driverPhone,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.badge,
                  label: 'الرقم القومي',
                  value: bus.driverNationalId.isNotEmpty ? bus.driverNationalId : 'غير محدد',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.people,
                  label: 'السعة',
                  value: '${bus.capacity} طالب',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.ac_unit,
                  label: 'التكييف',
                  value: bus.hasAirConditioning ? 'متوفر' : 'غير متوفر',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.description,
                  label: 'الوصف',
                  value: bus.description.isNotEmpty ? bus.description : 'لا يوجد',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditBusDialog(bus),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleBusStatus(bus),
                  icon: Icon(
                    bus.isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(bus.isActive ? 'إيقاف' : 'تفعيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bus.isActive ? Colors.orange : const Color(0xFF4CAF50),
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

  void _showAddBusDialog() {
    _showBusDialog();
  }

  void _showEditBusDialog(BusModel bus) {
    _showBusDialog(bus: bus);
  }

  void _showBusDialog({BusModel? bus}) {
    final isEditing = bus != null;
    final plateNumberController = TextEditingController(text: bus?.plateNumber ?? '');
    final descriptionController = TextEditingController(text: bus?.description ?? '');
    final driverNameController = TextEditingController(text: bus?.driverName ?? '');
    final driverPhoneController = TextEditingController(text: bus?.driverPhone ?? '');
    final driverNationalIdController = TextEditingController(text: bus?.driverNationalId ?? '');
    final routeController = TextEditingController(text: bus?.route ?? '');
    final capacityController = TextEditingController(text: bus?.capacity.toString() ?? '30');
    bool hasAirConditioning = bus?.hasAirConditioning ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'تعديل السيارة' : 'إضافة سيارة جديدة'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: 'خط السير',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم السائق',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'هاتف السائق',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: driverNationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم القومي للسائق',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'سعة السيارة',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف السيارة (اختياري)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('يوجد تكييف'),
                    value: hasAirConditioning,
                    onChanged: (value) {
                      setState(() {
                        hasAirConditioning = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveBus(
                  context: context,
                  isEditing: isEditing,
                  busId: bus?.id,
                  plateNumber: plateNumberController.text,
                  description: descriptionController.text,
                  driverName: driverNameController.text,
                  driverPhone: driverPhoneController.text,
                  driverNationalId: driverNationalIdController.text,
                  route: routeController.text,
                  capacity: int.tryParse(capacityController.text) ?? 30,
                  hasAirConditioning: hasAirConditioning,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة السيارة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBus({
    required BuildContext context,
    required bool isEditing,
    String? busId,
    required String plateNumber,
    required String description,
    required String driverName,
    required String driverPhone,
    required String driverNationalId,
    required String route,
    required int capacity,
    required bool hasAirConditioning,
  }) async {
    if (plateNumber.trim().isEmpty ||
        driverName.trim().isEmpty ||
        route.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى ملء جميع الحقول المطلوبة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (isEditing && busId != null) {
        // Update existing bus
        final existingBus = await _databaseService.getBus(busId);
        if (existingBus != null) {
          final updatedBus = existingBus.copyWith(
            plateNumber: plateNumber.trim(),
            description: description.trim(),
            driverName: driverName.trim(),
            driverPhone: driverPhone.trim(),
            driverNationalId: driverNationalId.trim(),
            route: route.trim(),
            capacity: capacity,
            hasAirConditioning: hasAirConditioning,
            updatedAt: DateTime.now(),
          );
          await _databaseService.updateBus(updatedBus);
        }
      } else {
        // Add new bus
        final newBus = BusModel(
          id: _databaseService.generateTripId(),
          plateNumber: plateNumber.trim(),
          description: description.trim(),
          driverName: driverName.trim(),
          driverPhone: driverPhone.trim(),
          driverNationalId: driverNationalId.trim(),
          route: route.trim(),
          capacity: capacity,
          hasAirConditioning: hasAirConditioning,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.addBus(newBus);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'تم تحديث السيارة بنجاح' : 'تم إضافة السيارة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving bus: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog even on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBusStatus(BusModel bus) async {
    try {
      final updatedBus = bus.copyWith(
        isActive: !bus.isActive,
        updatedAt: DateTime.now(),
      );
      await _databaseService.updateBus(updatedBus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bus.isActive ? 'تم إيقاف السيارة' : 'تم تفعيل السيارة',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة السيارة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
