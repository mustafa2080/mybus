import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/supervisor_evaluation_model.dart';
import '../../models/student_behavior_model.dart';

class SurveysReportsScreen extends StatefulWidget {
  const SurveysReportsScreen({super.key});

  @override
  State<SurveysReportsScreen> createState() => _SurveysReportsScreenState();
}

class _SurveysReportsScreenState extends State<SurveysReportsScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  List<SupervisorEvaluationModel> _supervisorEvaluations = [];
  List<StudentBehaviorEvaluation> _behaviorEvaluations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Loading reports for $_selectedMonth/$_selectedYear');

      // Load supervisor evaluations
      final supervisorEvals = await _databaseService.getSupervisorEvaluationsByMonth(_selectedMonth, _selectedYear);
      debugPrint('📊 Loaded ${supervisorEvals.length} supervisor evaluations');

      // Load behavior evaluations
      final behaviorEvals = await _databaseService.getBehaviorEvaluationsByMonth(_selectedMonth, _selectedYear);
      debugPrint('📊 Loaded ${behaviorEvals.length} behavior evaluations');

      if (mounted) {
        setState(() {
          _supervisorEvaluations = supervisorEvals;
          _behaviorEvaluations = behaviorEvals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل التقارير: $e'),
            backgroundColor: Colors.red,
          ),
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
          'تقارير الاستبيانات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'تصفية حسب الشهر',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics),
              text: 'ملخص عام',
            ),
            Tab(
              icon: Icon(Icons.supervisor_account),
              text: 'تقييم المشرفين',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: 'سلوك الطلاب',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month/Year selector
          _buildMonthYearSelector(),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل التقارير...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSupervisorEvaluationsTab(),
                      _buildBehaviorEvaluationsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Icon(Icons.calendar_month, color: Color(0xFF1E88E5)),
          const SizedBox(width: 8),
          Text(
            'التقرير لشهر:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E88E5).withAlpha(76)),
              ),
              child: Text(
                '${_getMonthName(_selectedMonth)} $_selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('تغيير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final supervisorAverage = _calculateSupervisorAverage();
    final behaviorAverage = _calculateBehaviorAverage();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'تقييمات المشرفين',
                  value: '${_supervisorEvaluations.length}',
                  subtitle: 'تقييم',
                  color: Colors.blue,
                  icon: Icons.supervisor_account,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'تقييمات السلوك',
                  value: '${_behaviorEvaluations.length}',
                  subtitle: 'تقييم',
                  color: Colors.green,
                  icon: Icons.school,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'متوسط تقييم المشرفين',
                  value: supervisorAverage.toStringAsFixed(1),
                  subtitle: 'من 5',
                  color: Colors.orange,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'متوسط سلوك الطلاب',
                  value: behaviorAverage.toStringAsFixed(1),
                  subtitle: 'من 5',
                  color: Colors.purple,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top performers
          _buildTopPerformersSection(),

          const SizedBox(height: 24),

          // Areas for improvement
          _buildImprovementAreasSection(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(25), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'أفضل الأداءات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top supervisors
            if (_supervisorEvaluations.isNotEmpty) ...[
              Text(
                'أفضل المشرفين:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getTopSupervisors().map((eval) => _buildTopPerformerItem(
                name: eval.supervisorName,
                score: eval.averageRating,
                type: 'مشرف',
              )),
            ],

            const SizedBox(height: 16),

            // Top students
            if (_behaviorEvaluations.isNotEmpty) ...[
              Text(
                'أفضل الطلاب سلوكاً:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getTopStudents().map((eval) => _buildTopPerformerItem(
                name: eval.studentName,
                score: eval.averageScore,
                type: 'طالب',
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerItem({
    required String name,
    required double score,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            type == 'مشرف' ? Icons.supervisor_account : Icons.school,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementAreasSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'مجالات التحسين',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Low performing supervisors
            if (_supervisorEvaluations.isNotEmpty) ...[
              Text(
                'المشرفين الذين يحتاجون تحسين:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getLowPerformingSupervisors().map((eval) => _buildImprovementItem(
                name: eval.supervisorName,
                score: eval.averageRating,
                type: 'مشرف',
              )),
            ],

            const SizedBox(height: 16),

            // Students needing attention
            if (_behaviorEvaluations.isNotEmpty) ...[
              Text(
                'الطلاب الذين يحتاجون اهتمام:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getStudentsNeedingAttention().map((eval) => _buildImprovementItem(
                name: eval.studentName,
                score: eval.averageScore,
                type: 'طالب',
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementItem({
    required String name,
    required double score,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            type == 'مشرف' ? Icons.supervisor_account : Icons.school,
            color: Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorEvaluationsTab() {
    if (_supervisorEvaluations.isEmpty) {
      return _buildEmptyState('لا توجد تقييمات للمشرفين في هذا الشهر');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _supervisorEvaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _supervisorEvaluations[index];
        return _buildSupervisorEvaluationCard(evaluation);
      },
    );
  }

  Widget _buildBehaviorEvaluationsTab() {
    if (_behaviorEvaluations.isEmpty) {
      return _buildEmptyState('لا توجد تقييمات سلوك في هذا الشهر');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _behaviorEvaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _behaviorEvaluations[index];
        return _buildBehaviorEvaluationCard(evaluation);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الشهر أو السنة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorEvaluationCard(SupervisorEvaluationModel evaluation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    evaluation.supervisorName.isNotEmpty ? evaluation.supervisorName[0] : 'م',
                    style: TextStyle(
                      color: Colors.blue[700],
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
                        evaluation.supervisorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'تقييم من: ${evaluation.parentName}',
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
                    color: _getScoreColor(evaluation.averageRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${evaluation.averageRating.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ratings breakdown
            Text(
              'تفاصيل التقييم:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            ...evaluation.ratings.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    entry.value.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(entry.value.value.toDouble()),
                    ),
                  ),
                ],
              ),
            )),

            if (evaluation.comments != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تعليق: ${evaluation.comments}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorEvaluationCard(StudentBehaviorEvaluation evaluation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green[100],
                  child: Text(
                    evaluation.studentName.isNotEmpty ? evaluation.studentName[0] : 'ط',
                    style: TextStyle(
                      color: Colors.green[700],
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
                        evaluation.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'تقييم من: ${evaluation.supervisorName}',
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
                    color: _getScoreColor(evaluation.averageScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${evaluation.averageScore.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Behavior categories
            Text(
              'تقييم السلوك:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: _buildBehaviorItem('الانضباط', evaluation.disciplineRating)),
                const SizedBox(width: 8),
                Expanded(child: _buildBehaviorItem('الاحترام', evaluation.respectRating)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildBehaviorItem('التعاون', evaluation.cooperationRating)),
                const SizedBox(width: 8),
                Expanded(child: _buildBehaviorItem('النظافة', evaluation.cleanlinessRating)),
              ],
            ),

            if (evaluation.positivePoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'نقاط إيجابية: ${evaluation.positivePoints}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorItem(String label, int rating) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getScoreColor(rating.toDouble()).withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '$rating/5',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(rating.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateSupervisorAverage() {
    if (_supervisorEvaluations.isEmpty) return 0.0;
    final total = _supervisorEvaluations.map((e) => e.averageRating).reduce((a, b) => a + b);
    return total / _supervisorEvaluations.length;
  }

  double _calculateBehaviorAverage() {
    if (_behaviorEvaluations.isEmpty) return 0.0;
    final total = _behaviorEvaluations.map((e) => e.averageScore).reduce((a, b) => a + b);
    return total / _behaviorEvaluations.length;
  }

  List<SupervisorEvaluationModel> _getTopSupervisors() {
    final sorted = List<SupervisorEvaluationModel>.from(_supervisorEvaluations);
    sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(3).toList();
  }

  List<StudentBehaviorEvaluation> _getTopStudents() {
    final sorted = List<StudentBehaviorEvaluation>.from(_behaviorEvaluations);
    sorted.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    return sorted.take(3).toList();
  }

  List<SupervisorEvaluationModel> _getLowPerformingSupervisors() {
    final filtered = _supervisorEvaluations.where((e) => e.averageRating < 3.0).toList();
    filtered.sort((a, b) => a.averageRating.compareTo(b.averageRating));
    return filtered.take(3).toList();
  }

  List<StudentBehaviorEvaluation> _getStudentsNeedingAttention() {
    final filtered = _behaviorEvaluations.where((e) => e.averageScore < 3.0).toList();
    filtered.sort((a, b) => a.averageScore.compareTo(b.averageScore));
    return filtered.take(3).toList();
  }

  Color _getScoreColor(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.lightGreen;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الشهر والسنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'الشهر',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text(_getMonthName(month)),
                );
              }),
              onChanged: (value) {
                setState(() => _selectedMonth = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'السنة',
                border: OutlineInputBorder(),
              ),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - 2 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                setState(() => _selectedYear = value!);
              },
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
              _loadReports();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }
}
