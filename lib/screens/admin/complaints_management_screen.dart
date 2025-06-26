import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/complaint_model.dart';
import '../../widgets/custom_button.dart';

class ComplaintsManagementScreen extends StatefulWidget {
  const ComplaintsManagementScreen({super.key});

  @override
  State<ComplaintsManagementScreen> createState() => _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState extends State<ComplaintsManagementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _databaseService.getComplaintsStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إدارة الشكاوى'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          isScrollable: true,
          tabs: [
            Tab(
              text: 'الكل (${_stats['total'] ?? 0})',
              icon: const Icon(Icons.all_inbox, size: 18),
            ),
            Tab(
              text: 'جديدة (${_stats['pending'] ?? 0})',
              icon: const Icon(Icons.new_releases, size: 18),
            ),
            Tab(
              text: 'قيد المعالجة (${_stats['inProgress'] ?? 0})',
              icon: const Icon(Icons.pending_actions, size: 18),
            ),
            Tab(
              text: 'محلولة (${_stats['resolved'] ?? 0})',
              icon: const Icon(Icons.check_circle, size: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsCards(),
          
          // Complaints List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComplaintsList(null), // All complaints
                _buildComplaintsList(ComplaintStatus.pending),
                _buildComplaintsList(ComplaintStatus.inProgress),
                _buildComplaintsList(ComplaintStatus.resolved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'عاجلة',
              _stats['urgent'] ?? 0,
              Colors.red,
              Icons.priority_high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'عالية',
              _stats['high'] ?? 0,
              Colors.orange,
              Icons.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'الإجمالي',
              _stats['total'] ?? 0,
              Colors.blue,
              Icons.feedback,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(ComplaintStatus? status) {
    return StreamBuilder<List<ComplaintModel>>(
      stream: status == null 
          ? _databaseService.getAllComplaints()
          : _databaseService.getComplaintsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الشكاوى: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadStats();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _buildComplaintCard(complaint);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ComplaintStatus? status) {
    String message;
    IconData icon;
    
    switch (status) {
      case ComplaintStatus.pending:
        message = 'لا توجد شكاوى جديدة';
        icon = Icons.new_releases_outlined;
        break;
      case ComplaintStatus.inProgress:
        message = 'لا توجد شكاوى قيد المعالجة';
        icon = Icons.pending_actions_outlined;
        break;
      case ComplaintStatus.resolved:
        message = 'لا توجد شكاوى محلولة';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'لا توجد شكاوى';
        icon = Icons.feedback_outlined;
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
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getPriorityColor(complaint.priority).withAlpha(76),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(complaint.status).withAlpha(25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildPriorityBadge(complaint.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.typeDisplayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            complaint.parentName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (complaint.studentName != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.school, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              complaint.studentName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(complaint.status),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(complaint.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (complaint.attachments.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.attachments.length} مرفق',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  children: [
                    if (complaint.status == ComplaintStatus.pending) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'بدء المعالجة',
                          onPressed: () => _updateStatus(complaint, ComplaintStatus.inProgress),
                          backgroundColor: Colors.blue,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (complaint.status == ComplaintStatus.inProgress) ...[
                      Expanded(
                        child: CustomButton(
                          text: 'إضافة رد',
                          onPressed: () => _showResponseDialog(complaint),
                          backgroundColor: Colors.green,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: CustomButton(
                        text: 'عرض التفاصيل',
                        onPressed: () => _showComplaintDetails(complaint),
                        backgroundColor: Colors.grey[600],
                        height: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ComplaintStatus status) {
    Color color;
    String text;

    switch (status) {
      case ComplaintStatus.pending:
        color = Colors.orange;
        text = 'جديدة';
        break;
      case ComplaintStatus.inProgress:
        color = Colors.blue;
        text = 'قيد المعالجة';
        break;
      case ComplaintStatus.resolved:
        color = Colors.green;
        text = 'محلولة';
        break;
      case ComplaintStatus.closed:
        color = Colors.grey;
        text = 'مغلقة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(ComplaintPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case ComplaintPriority.low:
        color = Colors.green;
        text = 'منخفضة';
        break;
      case ComplaintPriority.medium:
        color = Colors.orange;
        text = 'متوسطة';
        break;
      case ComplaintPriority.high:
        color = Colors.red;
        text = 'عالية';
        break;
      case ComplaintPriority.urgent:
        color = Colors.purple;
        text = 'عاجلة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;
      case ComplaintPriority.urgent:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _updateStatus(ComplaintModel complaint, ComplaintStatus newStatus) async {
    try {
      await _databaseService.updateComplaintStatus(complaint.id, newStatus);
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الحالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResponseDialog(ComplaintModel complaint) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة رد على الشكوى'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الشكوى: ${complaint.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'رد الإدارة',
                hintText: 'اكتب رد الإدارة على الشكوى...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isNotEmpty) {
                try {
                  await _databaseService.addComplaintResponse(
                    complaint.id,
                    responseController.text.trim(),
                    'admin', // Replace with actual admin ID
                  );
                  await _loadStats();

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إضافة الرد بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في إضافة الرد: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complaint.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('النوع', complaint.typeDisplayName),
              _buildDetailRow('الأولوية', complaint.priorityDisplayName),
              _buildDetailRow('الحالة', complaint.statusDisplayName),
              _buildDetailRow('ولي الأمر', complaint.parentName),
              _buildDetailRow('رقم الهاتف', complaint.parentPhone),
              if (complaint.studentName != null)
                _buildDetailRow('الطالب', complaint.studentName!),
              _buildDetailRow('التاريخ', _formatDate(complaint.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'التفاصيل:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(complaint.description),
              if (complaint.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'المرفقات: ${complaint.attachments.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (complaint.adminResponse != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'رد الإدارة:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(complaint.adminResponse!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
}


