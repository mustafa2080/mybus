import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/absence_model.dart';
import '../../services/database_service.dart';
import '../../widgets/curved_app_bar.dart';

class AbsenceManagementScreen extends StatefulWidget {
  const AbsenceManagementScreen({super.key});

  @override
  State<AbsenceManagementScreen> createState() => _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState extends State<AbsenceManagementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: EnhancedCurvedAppBar(
        title: 'إشعارات الغياب',
        subtitle: const Text('متابعة إشعارات الغياب من أولياء الأمور'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Header with Statistics
          _buildHeader(),
          const SizedBox(height: 16),

          // Tab Bar - Enhanced for better visibility
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF1E88E5),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                ),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.notifications_active, size: 20),
                    text: 'إشعارات حديثة',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 20),
                    text: 'جميع الإشعارات',
                    height: 70,
                  ),
                  Tab(
                    icon: Icon(Icons.analytics, size: 20),
                    text: 'الإحصائيات',
                    height: 70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentAbsences(),
                _buildAllAbsences(),
                _buildAbsenceStatistics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE91E63),
            Color(0xFFAD1457),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إشعارات الغياب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'متابعة إشعارات الغياب من أولياء الأمور',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Stats
          StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getAllAbsencesStream(),
            builder: (context, snapshot) {
              final allAbsences = snapshot.data ?? [];
              final parentAbsences = allAbsences.where((a) => a.source == AbsenceSource.parent).toList();
              final pendingCount = parentAbsences.where((a) => a.status == AbsenceStatus.pending).length;
              final approvedCount = parentAbsences.where((a) => a.status == AbsenceStatus.approved).length;
              final rejectedCount = parentAbsences.where((a) => a.status == AbsenceStatus.rejected).length;
              final totalCount = parentAbsences.length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'اليوم',
                      _getTodayAbsencesCount(parentAbsences).toString(),
                      Icons.today,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'هذا الأسبوع',
                      _getWeekAbsencesCount(parentAbsences).toString(),
                      Icons.date_range,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'هذا الشهر',
                      _getMonthAbsencesCount(parentAbsences).toString(),
                      Icons.calendar_month,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'الإجمالي',
                      totalCount.toString(),
                      Icons.assessment,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAbsences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'الإشعارات الحديثة (آخر 7 أيام)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
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

                final allAbsences = snapshot.data ?? [];

                // فلترة الإشعارات الحديثة من أولياء الأمور (آخر 7 أيام)
                final recentDate = DateTime.now().subtract(const Duration(days: 7));
                final recentParentNotifications = allAbsences
                    .where((absence) =>
                        absence.source == AbsenceSource.parent &&
                        absence.createdAt.isAfter(recentDate))
                    .toList();

                // ترتيب حسب التاريخ (الأحدث أولاً)
                recentParentNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (recentParentNotifications.isEmpty) {
                  return _buildEmptyStateWithDemo(
                    'لا توجد إشعارات حديثة',
                    'لم يتم إرسال إشعارات غياب في آخر 7 أيام',
                    Icons.notifications_off,
                    Colors.blue,
                    'recent',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: recentParentNotifications.length,
                  itemBuilder: (context, index) {
                    final absence = recentParentNotifications[index];
                    return _buildSimpleAbsenceCard(absence);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAbsences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.history, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'جميع الإشعارات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAbsences = snapshot.data ?? [];
                final parentAbsences = allAbsences
                    .where((absence) => absence.source == AbsenceSource.parent)
                    .toList();

                // ترتيب حسب التاريخ (الأحدث أولاً)
                parentAbsences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (parentAbsences.isEmpty) {
                  return _buildEmptyStateWithDemo(
                    'لا توجد إشعارات غياب',
                    'لم يرسل أولياء الأمور أي إشعارات غياب بعد',
                    Icons.notifications_off,
                    Colors.green,
                    'all',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: parentAbsences.length,
                  itemBuilder: (context, index) {
                    final absence = parentAbsences[index];
                    return _buildSimpleAbsenceCard(absence);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceStatistics() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'الإحصائيات والتقارير',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getAllAbsencesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allAbsences = snapshot.data ?? [];
                final parentAbsences = allAbsences
                    .where((absence) => absence.source == AbsenceSource.parent)
                    .toList();

                if (parentAbsences.isEmpty) {
                  return _buildEmptyStateWithDemo(
                    'لا توجد بيانات للإحصائيات',
                    'لا توجد إشعارات غياب لعرض الإحصائيات',
                    Icons.analytics,
                    Colors.purple,
                    'stats',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatisticsCard('إحصائيات الغياب', [
                        _buildStatRow('إجمالي الإشعارات', parentAbsences.length.toString()),
                        _buildStatRow('إشعارات اليوم', _getTodayAbsencesCount(parentAbsences).toString()),
                        _buildStatRow('إشعارات هذا الأسبوع', _getWeekAbsencesCount(parentAbsences).toString()),
                        _buildStatRow('إشعارات هذا الشهر', _getMonthAbsencesCount(parentAbsences).toString()),
                      ]),
                      const SizedBox(height: 16),
                      _buildStatisticsCard('أنواع الغياب', [
                        _buildStatRow('مرض', _getAbsenceTypeCount(parentAbsences, AbsenceType.sick).toString()),
                        _buildStatRow('ظروف عائلية', _getAbsenceTypeCount(parentAbsences, AbsenceType.family).toString()),
                        _buildStatRow('سفر', _getAbsenceTypeCount(parentAbsences, AbsenceType.travel).toString()),
                        _buildStatRow('طوارئ', _getAbsenceTypeCount(parentAbsences, AbsenceType.emergency).toString()),
                        _buildStatRow('أخرى', _getAbsenceTypeCount(parentAbsences, AbsenceType.other).toString()),
                      ]),
                      const SizedBox(height: 16),
                      _buildStatisticsCard('حالة الإشعارات', [
                        _buildStatRow('معلقة', parentAbsences.where((a) => a.status == AbsenceStatus.pending).length.toString()),
                        _buildStatRow('مقبولة', parentAbsences.where((a) => a.status == AbsenceStatus.approved).length.toString()),
                        _buildStatRow('مرفوضة', parentAbsences.where((a) => a.status == AbsenceStatus.rejected).length.toString()),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithDemo(String title, String subtitle, IconData icon, Color color, String tabType) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'معاينة التاب: $tabType',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDemoContent(tabType),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDemoContent(String tabType) {
    switch (tabType) {
      case 'recent':
        return 'هنا ستظهر الإشعارات الحديثة من آخر 7 أيام\nمثل: إشعار غياب أحمد محمد - مرض\nإشعار غياب فاطمة علي - ظروف عائلية';
      case 'all':
        return 'هنا ستظهر جميع إشعارات الغياب\nمرتبة من الأحدث إلى الأقدم\nمع إمكانية الموافقة أو الرفض';
      case 'stats':
        return 'هنا ستظهر الإحصائيات التفصيلية\nعدد الإشعارات اليومية والأسبوعية\nتوزيع أنواع الغياب والحالات';
      default:
        return 'محتوى تجريبي للتاب';
    }
  }

  Widget _buildSimpleAbsenceCard(AbsenceModel absence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(absence.status).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_off,
                    color: _getStatusColor(absence.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        absence.typeDisplayText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(absence.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    absence.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'تاريخ الغياب: ${_formatDate(absence.date)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (absence.endDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'إلى تاريخ: ${_formatDate(absence.endDate!)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'تم الإرسال: ${_formatDateTime(absence.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'السبب: ${absence.reason}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (absence.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظات: ${absence.notes}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            // Notification Status
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'تم استلام الإشعار',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'من ${absence.approvedBy ?? 'ولي الأمر'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Helper methods for statistics
  int _getTodayAbsencesCount(List<AbsenceModel> absences) {
    final today = DateTime.now();
    return absences.where((absence) {
      return absence.date.year == today.year &&
          absence.date.month == today.month &&
          absence.date.day == today.day;
    }).length;
  }

  int _getWeekAbsencesCount(List<AbsenceModel> absences) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return absences.where((absence) => absence.date.isAfter(weekStart)).length;
  }

  int _getMonthAbsencesCount(List<AbsenceModel> absences) {
    final now = DateTime.now();
    return absences.where((absence) {
      return absence.date.year == now.year && absence.date.month == now.month;
    }).length;
  }

  int _getAbsenceTypeCount(List<AbsenceModel> absences, AbsenceType type) {
    return absences.where((absence) => absence.type == type).length;
  }

  Widget _buildStatisticsCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }



  Color _getStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

}


