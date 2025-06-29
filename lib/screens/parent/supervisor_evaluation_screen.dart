import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/supervisor_evaluation_model.dart';
import 'evaluate_supervisor_screen.dart';

class SupervisorEvaluationScreen extends StatefulWidget {
  const SupervisorEvaluationScreen({super.key});

  @override
  State<SupervisorEvaluationScreen> createState() => _SupervisorEvaluationScreenState();
}

class _SupervisorEvaluationScreenState extends State<SupervisorEvaluationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  List<UserModel> _supervisors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    try {
      final parentId = _authService.currentUser?.uid ?? '';
      if (parentId.isNotEmpty) {
        final supervisors = await _databaseService.getSupervisorsForParent(parentId);
        setState(() {
          _supervisors = supervisors;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading supervisors: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تقييم المشرفين',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _supervisors.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Header info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'معلومات مهمة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يمكنك تقييم المشرفين المسؤولين عن أطفالك مرة واحدة شهرياً. تقييمك يساعد في تحسين جودة الخدمة.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Supervisors list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _supervisors.length,
                        itemBuilder: (context, index) {
                          final supervisor = _supervisors[index];
                          return _buildSupervisorCard(supervisor);
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
            Icons.supervisor_account_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مشرفين للتقييم',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تعيين مشرفين لأطفالك بعد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorCard(UserModel supervisor) {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supervisor info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    supervisor.name.isNotEmpty ? supervisor.name[0] : 'م',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supervisor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مشرف/ة الباص',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Evaluation status and button
            FutureBuilder<bool>(
              future: _databaseService.hasEvaluatedSupervisorThisMonth(
                _authService.currentUser?.uid ?? '',
                supervisor.id,
                currentMonth,
                currentYear,
              ),
              builder: (context, snapshot) {
                final hasEvaluated = snapshot.data ?? false;
                
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasEvaluated ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasEvaluated ? Colors.green[200]! : Colors.orange[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasEvaluated ? Icons.check_circle : Icons.pending,
                              color: hasEvaluated ? Colors.green[600] : Colors.orange[600],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasEvaluated ? 'تم التقييم هذا الشهر' : 'لم يتم التقييم بعد',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasEvaluated ? Colors.green[700] : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: hasEvaluated ? null : () => _evaluateSupervisor(supervisor),
                      icon: Icon(
                        hasEvaluated ? Icons.done : Icons.rate_review,
                        size: 16,
                      ),
                      label: Text(hasEvaluated ? 'تم التقييم' : 'تقييم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasEvaluated ? Colors.grey : const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _evaluateSupervisor(UserModel supervisor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluateSupervisorScreen(
          supervisor: supervisor,
          onEvaluationComplete: () {
            setState(() {}); // Refresh the screen
          },
        ),
      ),
    );
  }
}
