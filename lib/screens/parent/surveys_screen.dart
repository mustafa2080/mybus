import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/survey_model.dart';
import '../../models/user_model.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = UserModel.fromMap(userData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'الاستبيانات',
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
            icon: const Icon(Icons.supervisor_account),
            onPressed: () {
              Navigator.pushNamed(context, '/parent/supervisor-evaluation');
            },
            tooltip: 'تقييم المشرفين',
          ),
        ],
      ),
      body: Column(
        children: [
          // Supervisor evaluation card
          Container(
            margin: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/parent/supervisor-evaluation');
              },
              child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.supervisor_account,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تقييم المشرفين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قيم أداء المشرفين المسؤولين عن أطفالك',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(230),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),

          // Regular surveys
          Expanded(
            child: StreamBuilder<List<SurveyModel>>(
        stream: _databaseService.getActiveSurveysForUser('parent'),
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
                  Text('خطأ في تحميل الاستبيانات: ${snapshot.error}'),
                ],
              ),
            );
          }

          final surveys = snapshot.data ?? [];

          if (surveys.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surveys.length,
            itemBuilder: (context, index) {
              final survey = surveys[index];
              return _buildSurveyCard(survey);
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
            Icons.poll_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد استبيانات متاحة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إشعارك عند توفر استبيانات جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(SurveyModel survey) {
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
                  color: const Color(0xFF1E88E5).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.poll,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      survey.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      survey.typeDisplayName,
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
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  survey.statusDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            survey.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Row
          Row(
            children: [
              Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${survey.questions.length} سؤال',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              if (survey.expiresAt != null) ...[
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'ينتهي في ${_formatDate(survey.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Button
          FutureBuilder<bool>(
            future: _currentUser != null 
                ? _databaseService.hasUserRespondedToSurvey(survey.id, _currentUser!.id)
                : Future.value(false),
            builder: (context, hasRespondedSnapshot) {
              final hasResponded = hasRespondedSnapshot.data ?? false;
              
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasResponded ? null : () => _takeSurvey(survey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasResponded ? Colors.grey : const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasResponded ? 'تم الإجابة على الاستبيان' : 'بدء الاستبيان',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'غداً';
    } else if (difference > 1) {
      return 'خلال $difference أيام';
    } else {
      return 'منتهي الصلاحية';
    }
  }

  void _takeSurvey(SurveyModel survey) {
    context.push('/parent/take-survey/${survey.id}');
  }
}
