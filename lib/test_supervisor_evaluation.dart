import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'models/supervisor_evaluation_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await testSupervisorEvaluation();
}

Future<void> testSupervisorEvaluation() async {
  final databaseService = DatabaseService();
  
  try {
    print('🧪 Testing Supervisor Evaluation System...');
    
    // Create a test evaluation
    final testEvaluation = SupervisorEvaluationModel(
      id: 'test_eval_${DateTime.now().millisecondsSinceEpoch}',
      supervisorId: 'test_supervisor_id',
      supervisorName: 'أحمد محمد - مشرف تجريبي',
      parentId: 'test_parent_id',
      parentName: 'سارة أحمد - ولي أمر تجريبي',
      studentId: 'test_student_id',
      studentName: 'محمد أحمد - طالب تجريبي',
      busId: 'test_bus_id',
      ratings: {
        EvaluationCategory.communication: EvaluationRating.excellent,
        EvaluationCategory.punctuality: EvaluationRating.veryGood,
        EvaluationCategory.safety: EvaluationRating.excellent,
        EvaluationCategory.professionalism: EvaluationRating.good,
        EvaluationCategory.studentCare: EvaluationRating.excellent,
      },
      comments: 'المشرف ممتاز في التعامل مع الأطفال ويحرص على سلامتهم',
      suggestions: 'يمكن تحسين التواصل مع أولياء الأمور',
      evaluatedAt: DateTime.now(),
      month: DateTime.now().month,
      year: DateTime.now().year,
    );
    
    // Save the evaluation
    await databaseService.createSupervisorEvaluation(testEvaluation);
    print('✅ Test evaluation created successfully!');
    
    // Test retrieving evaluations
    final evaluations = await databaseService.getSupervisorEvaluations('test_supervisor_id');
    print('📊 Retrieved ${evaluations.length} evaluations');
    
    if (evaluations.isNotEmpty) {
      final eval = evaluations.first;
      print('📝 Evaluation Details:');
      print('   - Supervisor: ${eval.supervisorName}');
      print('   - Parent: ${eval.parentName}');
      print('   - Student: ${eval.studentName}');
      print('   - Comments: ${eval.comments}');
      print('   - Suggestions: ${eval.suggestions}');
      print('   - Ratings:');
      eval.ratings.forEach((category, rating) {
        print('     * ${_getCategoryName(category)}: ${_getRatingName(rating)}');
      });
    }
    
    print('🎉 Supervisor Evaluation System is working correctly!');
    
  } catch (e) {
    print('❌ Error testing supervisor evaluation: $e');
  }
}

String _getCategoryName(EvaluationCategory category) {
  switch (category) {
    case EvaluationCategory.communication:
      return 'التواصل';
    case EvaluationCategory.punctuality:
      return 'الالتزام بالمواعيد';
    case EvaluationCategory.safety:
      return 'السلامة';
    case EvaluationCategory.professionalism:
      return 'المهنية';
    case EvaluationCategory.studentCare:
      return 'العناية بالطلاب';
  }
}

String _getRatingName(EvaluationRating rating) {
  switch (rating) {
    case EvaluationRating.excellent:
      return 'ممتاز';
    case EvaluationRating.veryGood:
      return 'جيد جداً';
    case EvaluationRating.good:
      return 'جيد';
    case EvaluationRating.fair:
      return 'مقبول';
    case EvaluationRating.poor:
      return 'ضعيف';
  }
}
