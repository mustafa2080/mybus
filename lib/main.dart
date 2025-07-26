import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/notification_system_initializer.dart';
import 'services/firebase_messaging_service.dart';
import 'utils/app_constants.dart';
import 'utils/app_validator.dart';

/// معالج الإشعارات في الخلفية - يجب أن يكون دالة عامة في المستوى الأعلى
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تهيئة Firebase للخلفية
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📱 استلام إشعار في الخلفية: ${message.messageId}');
  print('📱 العنوان: ${message.notification?.title}');
  print('📱 المحتوى: ${message.notification?.body}');

  // معالجة الإشعار في الخلفية
  await FirebaseMessagingService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // تسجيل معالج الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');

    // طباعة معلومات التطبيق
    AppValidator.printAppInfo();

    // فحص سريع للتطبيق
    final healthCheck = await AppValidator.quickHealthCheck();
    if (healthCheck) {
      print('✅ App health check passed');
    } else {
      print('⚠️ App health check failed');
    }

    // تهيئة نظام الإشعارات
    try {
      await initializeNotificationSystem();
      print('✅ Notification system initialized successfully');
    } catch (e) {
      print('❌ Notification system initialization error: $e');
    }

  } catch (e) {
    print('❌ Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // تسجيل جميع الخدمات كـ Providers
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // دعم اللغة العربية (RTL)
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'), // العربية
              Locale('en', 'US'), // الإنجليزية
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // تطبيق الثيم
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeService.themeMode,

            // نظام التوجيه
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }

  // بناء الثيم الفاتح
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: AppConstants.primaryColor,

      // ألوان التطبيق
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),

      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),

      // خلفية الشاشات
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),

      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // البطاقات
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // حقول النص
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // بناء الثيم الداكن
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: AppConstants.primaryColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
        color: const Color(0xFF1E1E1E),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}



// Widget للخلفية المشتركة
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), // أزرق فاتح
            Color(0xFF1E88E5), // أزرق متوسط
            Color(0xFF1565C0), // أزرق غامق
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
