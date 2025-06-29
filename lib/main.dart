import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/parent/complete_profile_screen.dart';
import 'screens/parent/parent_profile_screen.dart';
import 'screens/parent/help_screen.dart';
import 'screens/parent/add_student_screen.dart' as parent_add_student;
import 'screens/parent/simple_activity_screen.dart';
import 'screens/parent/notifications_screen.dart';
import 'screens/parent/surveys_screen.dart';
import 'screens/parent/take_survey_screen.dart';
import 'screens/supervisor/supervisor_home_screen.dart';
import 'screens/supervisor/qr_scanner_screen.dart';
import 'screens/supervisor/students_list_screen.dart';
import 'screens/supervisor/emergency_contact_screen.dart';
import 'screens/supervisor/supervisor_profile_screen.dart';
import 'screens/supervisor/supervisor_surveys_screen.dart';
import 'screens/supervisor/take_supervisor_survey_screen.dart';
import 'screens/admin/supervisor_assignments_screen.dart';
import 'screens/admin/buses_management_screen.dart';
import 'screens/supervisor/supervisor_notifications_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/add_student_screen.dart' as admin_add_student;
import 'screens/admin/edit_student_screen.dart';
import 'screens/admin/supervisors_management_screen.dart';
import 'screens/admin/parents_management_screen.dart';
import 'screens/admin/buses_management_screen.dart';
import 'screens/admin/all_students_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/advanced_analytics_screen.dart';
import 'screens/admin/complaints_management_screen.dart';
import 'screens/admin/absence_management_screen.dart';
import 'screens/admin/surveys_reports_screen.dart';
import 'screens/parent/parent_settings_screen.dart';
import 'screens/parent/bus_info_screen.dart';
import 'screens/parent/add_complaint_screen.dart';
import 'screens/parent/complaints_screen.dart';
import 'screens/parent/update_student_photo_screen.dart';
import 'screens/parent/supervisor_evaluation_screen.dart';
import 'screens/parent/evaluate_supervisor_screen.dart';

import 'widgets/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initializeTheme();

  // تشغيل التطبيق مع خدمة الثيم
  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'باصي - تتبع الطلاب',
            debugShowCheckedModeBanner: false,

            // RTL Support for Arabic
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'), // Arabic
              Locale('en', 'US'), // English
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: ThemeService.lightTheme.copyWith(
              // Ensure RTL text direction
              textTheme: ThemeService.lightTheme.textTheme.apply(
                fontFamily: 'Cairo',
              ),
            ),
            darkTheme: ThemeService.darkTheme.copyWith(
              // Ensure RTL text direction
              textTheme: ThemeService.darkTheme.textTheme.apply(
                fontFamily: 'Cairo',
              ),
            ),
            themeMode: themeService.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// Router configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentHomeScreen(),
    ),
    GoRoute(
      path: '/parent/complete-profile',
      builder: (context, state) {
        final isEditing = state.uri.queryParameters['edit'] == 'true';
        return CompleteProfileScreen(isEditing: isEditing);
      },
    ),
    GoRoute(
      path: '/parent/profile',
      builder: (context, state) => const ParentProfileScreen(),
    ),
    GoRoute(
      path: '/parent/help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/parent/student-activity/:studentId',
      builder: (context, state) {
        final studentId = state.pathParameters['studentId']!;
        return SimpleActivityScreen(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/parent/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/parent/settings',
      builder: (context, state) => const ParentSettingsScreen(),
    ),
    GoRoute(
      path: '/parent/bus-info/:studentId',
      builder: (context, state) {
        final studentId = state.pathParameters['studentId']!;
        return BusInfoScreen(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/parent/add-student',
      builder: (context, state) => const parent_add_student.AddStudentScreen(),
    ),
    GoRoute(
      path: '/parent/complaints',
      builder: (context, state) => const ComplaintsScreen(),
    ),
    GoRoute(
      path: '/parent/add-complaint',
      builder: (context, state) => const AddComplaintScreen(),
    ),
    GoRoute(
      path: '/parent/surveys',
      builder: (context, state) => const SurveysScreen(),
    ),
    GoRoute(
      path: '/parent/supervisor-evaluation',
      builder: (context, state) => const SupervisorEvaluationScreen(),
    ),
    GoRoute(
      path: '/parent/take-survey/:surveyId',
      builder: (context, state) {
        final surveyId = state.pathParameters['surveyId']!;
        return TakeSurveyScreen(surveyId: surveyId);
      },
    ),
    GoRoute(
      path: '/supervisor',
      builder: (context, state) => const SupervisorHomeScreen(),
    ),
    GoRoute(
      path: '/supervisor/qr-scanner',
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/supervisor/students-list',
      builder: (context, state) => const StudentsListScreen(),
    ),
    GoRoute(
      path: '/supervisor/emergency-contact',
      builder: (context, state) => const EmergencyContactScreen(),
    ),
    GoRoute(
      path: '/supervisor/profile',
      builder: (context, state) => const SupervisorProfileScreen(),
    ),
    GoRoute(
      path: '/supervisor/surveys',
      builder: (context, state) => const SupervisorSurveysScreen(),
    ),
    GoRoute(
      path: '/supervisor/take-survey/:surveyId',
      builder: (context, state) {
        final surveyId = state.pathParameters['surveyId']!;
        return TakeSupervisorSurveyScreen(surveyId: surveyId);
      },
    ),
    GoRoute(
      path: '/supervisor/notifications',
      builder: (context, state) => const SupervisorNotificationsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(
          location: state.fullPath ?? '/admin',
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminHomeScreen(),
        ),
        GoRoute(
          path: '/admin/students',
          builder: (context, state) => const AllStudentsScreen(),
        ),
        GoRoute(
          path: '/admin/supervisor-assignments',
          builder: (context, state) => const SupervisorAssignmentsScreen(),
        ),
        GoRoute(
          path: '/admin/buses-management',
          builder: (context, state) => const BusesManagementScreen(),
        ),
        GoRoute(
          path: '/admin/notifications',
          builder: (context, state) => const AdminNotificationsScreen(),
        ),
        GoRoute(
          path: '/admin/add-student',
          builder: (context, state) => const admin_add_student.AddStudentScreen(),
        ),
        GoRoute(
          path: '/admin/students/edit/:id',
          builder: (context, state) {
            final studentId = state.pathParameters['id']!;
            return EditStudentScreen(studentId: studentId);
          },
        ),
        GoRoute(
          path: '/admin/supervisors',
          builder: (context, state) => const SupervisorsManagementScreen(),
        ),
        GoRoute(
          path: '/admin/buses',
          builder: (context, state) => const BusesManagementScreen(),
        ),
        GoRoute(
          path: '/admin/parents',
          builder: (context, state) => const ParentsManagementScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/admin/advanced-analytics',
          builder: (context, state) => const AdvancedAnalyticsScreen(),
        ),
        GoRoute(
          path: '/admin/complaints',
          builder: (context, state) => const ComplaintsManagementScreen(),
        ),
        GoRoute(
          path: '/admin/absence-management',
          builder: (context, state) => const AbsenceManagementScreen(),
        ),
        GoRoute(
          path: '/admin/surveys-reports',
          builder: (context, state) => const SurveysReportsScreen(),
        ),
      ],
    ),
  ],
);