import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../main.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../utils/background_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // زيادة مدة الرسوم المتحركة لـ 3 ثواني
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // منحنى أكثر سلاسة
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.3, // بداية أصغر لتأثير أكثر وضوحاً
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: -150.0, // حركة أكبر
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // انتظار انتهاء الأنيميشن - زيادة الوقت ليشاهد المستخدم الشاشة بوضوح
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      try {
        // فحص حالة المستخدم
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          // المستخدم مسجل دخول - جلب بيانات المستخدم
          final AuthService authService = AuthService();
          final UserModel? userData = await authService.getUserData(currentUser.uid);

          if (userData != null) {
            // الانتقال حسب نوع المستخدم
            _navigateBasedOnUserType(userData.userType);
          } else {
            // بيانات المستخدم غير موجودة - الانتقال لتسجيل الدخول
            _navigateToLogin();
          }
        } else {
          // المستخدم غير مسجل دخول - الانتقال لصفحة تسجيل الدخول
          _navigateToLogin();
        }
      } catch (e) {
        print('Error checking auth status: $e');
        // في حالة الخطأ - الانتقال لتسجيل الدخول
        _navigateToLogin();
      }
    }
  }

  void _navigateBasedOnUserType(UserType userType) {
    String route;

    switch (userType) {
      case UserType.parent:
        route = AppRoutes.parentHome;
        break;
      case UserType.supervisor:
        route = AppRoutes.supervisorHome;
        break;
      case UserType.admin:
        route = AppRoutes.adminHome;
        break;
    }

    context.go(route);
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildBusIllustration() {
    return SizedBox(
      width: 280,
      height: 180,
      child: Stack(
        children: [
          // Bus Body
          Positioned(
            left: 20,
            top: 40,
            child: Container(
              width: 240,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700), // Golden yellow bus
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(76),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // Bus Front
          Positioned(
            left: 240,
            top: 50,
            child: Container(
              width: 30,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),

          // Bus Windows
          _buildBusWindow(40, 55, 0), // Driver window
          _buildBusWindow(80, 55, 1), // Window 1
          _buildBusWindow(120, 55, 2), // Window 2
          _buildBusWindow(160, 55, 3), // Window 3
          _buildBusWindow(200, 55, 4), // Window 4

          // Bus Wheels
          _buildWheel(50, 130),
          _buildWheel(200, 130),

          // Bus Door
          Positioned(
            left: 35,
            top: 80,
            child: Container(
              width: 25,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

          // Bus Headlight
          Positioned(
            left: 245,
            top: 70,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withAlpha(153),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // School Bus Text
          Positioned(
            left: 90,
            top: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'باص المدرسة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Floating Hearts/Stars around bus
          _buildFloatingIcon(Icons.favorite, Colors.pink, 10, 20, 0.8),
          _buildFloatingIcon(Icons.star, Colors.yellow, 250, 30, 1.2),
          _buildFloatingIcon(Icons.favorite, Colors.red, 15, 150, 1.0),
          _buildFloatingIcon(Icons.star, Colors.orange, 260, 140, 0.9),
        ],
      ),
    );
  }

  Widget _buildBusWindow(double left, double top, int kidIndex) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 30,
        height: 25,
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB), // Sky blue window
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: kidIndex == 0
          ? const Icon(Icons.person, size: 16, color: Color(0xFF2D3748)) // Driver
          : _buildKidInWindow(kidIndex),
      ),
    );
  }

  Widget _buildKidInWindow(int kidIndex) {
    final kidData = [
      {'color': Colors.brown, 'icon': Icons.boy, 'name': 'أحمد'},
      {'color': Colors.pink, 'icon': Icons.girl, 'name': 'فاطمة'},
      {'color': Colors.purple, 'icon': Icons.child_care, 'name': 'محمد'},
      {'color': Colors.green, 'icon': Icons.face, 'name': 'نور'},
    ];

    final kid = kidData[kidIndex % kidData.length];

    return Center(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500 + (kidIndex * 200)),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: kid['color'] as Color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (kid['color'] as Color).withAlpha(102), // 0.4 * 255 = 102
              blurRadius: 3,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          kid['icon'] as IconData,
          size: 8,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWheel(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animationController.value * 4 * 3.14159, // Multiple rotations
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(76), // 0.3 * 255 = 76
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, double left, double top, double scale) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: scale + (0.2 * _animationController.value),
            child: Transform.rotate(
              angle: _animationController.value * 2 * 3.14159,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(76),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color.withAlpha(204),
                  size: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Circle
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withAlpha(76)),
            strokeWidth: 2,
          ),
        ),
        // Inner Circle
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        // Center Icon
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(229),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 12,
            color: Color(0xFF667EEA),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLoadingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow effect
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Outer Circle with gradient
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              BackgroundUtils.busYellow.withOpacity(0.8),
            ),
            strokeWidth: 4,
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
        ),
        // Middle Circle
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
            backgroundColor: Colors.transparent,
          ),
        ),
        // Inner Circle
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              BackgroundUtils.schoolBlue,
            ),
            strokeWidth: 2,
            backgroundColor: Colors.transparent,
          ),
        ),
        // Center Icon with enhanced styling
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.9),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus,
            size: 18,
            color: BackgroundUtils.busYellow,
          ),
        ),
        // Animated dots around the loading
        ...List.generate(8, (index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final angle = (index * 45.0) + (_animationController.value * 360);
              final radians = angle * (3.14159 / 180);
              final radius = 50.0;

              return Positioned(
                left: radius * cos(radians),
                top: radius * sin(radians),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.3 + (0.7 * ((index + _animationController.value * 8) % 8) / 8),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BackgroundUtils.enhancedSplashBackground,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Top Section with Bus Illustration
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Bus with Kids Illustration
                              Transform.translate(
                                offset: Offset(_slideAnimation.value, 0),
                                child: _buildBusIllustration(),
                              ),
                              const SizedBox(height: 30),

                              // App Name with enhanced styling
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (_scaleAnimation.value * 0.2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'كيدز باصى',
                                        style: TextStyle(
                                          fontSize: 52, // زيادة حجم الخط أكثر
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 6, // زيادة المسافة بين الحروف
                                          shadows: [
                                            Shadow(
                                              offset: Offset(4, 4),
                                              blurRadius: 8,
                                              color: Colors.black54,
                                            ),
                                            Shadow(
                                              offset: Offset(-2, -2),
                                              blurRadius: 4,
                                              color: Colors.white38,
                                            ),
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 20,
                                              color: Colors.yellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              // App Subtitle with animation
                              AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.white.withOpacity(0.15),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.4),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'تتبع آمن وسهل لرحلة طفلك المدرسية',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(2, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black38,
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.security,
                                                  color: Colors.white.withOpacity(0.9),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'أمان • سهولة • راحة البال',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.favorite,
                                                  color: Colors.white.withOpacity(0.9),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Section with Loading
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Enhanced Loading Animation
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (0.1 * _animationController.value),
                                  child: _buildEnhancedLoadingAnimation(),
                                );
                              },
                            ),
                            const SizedBox(height: 25),

                            // Enhanced Loading Text with animation
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'جاري التحميل...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 3,
                                                color: Colors.black38,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'نحضر لك تجربة رائعة...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
