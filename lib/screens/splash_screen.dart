import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // تقليل وقت الانتظار للحصول على تشغيل أسرع
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // فحص سريع للمستخدم الحالي بدون انتظار stream
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('✅ مستخدم مسجل دخول: ${currentUser.email}');

        // User is logged in, get user data and navigate accordingly
        final UserModel? userData = await _authService.getUserData(currentUser.uid);

        if (userData != null && mounted) {
          debugPrint('✅ تم جلب بيانات المستخدم: ${userData.userType}');
          _navigateBasedOnUserType(userData.userType);
        } else if (mounted) {
          debugPrint('⚠️ لم يتم العثور على بيانات المستخدم، الانتقال لتسجيل الدخول');
          context.go('/login');
        }
      } else if (mounted) {
        debugPrint('🔒 لا يوجد مستخدم مسجل دخول، الانتقال لتسجيل الدخول');
        // User is not logged in, navigate to login
        context.go('/login');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة المصادقة: $e');
      // Error occurred, navigate to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _navigateBasedOnUserType(UserType userType) {
    switch (userType) {
      case UserType.parent:
        context.go('/parent');
        break;
      case UserType.supervisor:
        context.go('/supervisor');
        break;
      case UserType.admin:
        context.go('/admin');
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFF1E88E5),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
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

                              // App Name
                              const Text(
                                'كيدز باصى',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // App Subtitle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(76),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'تتبع آمن وسهل لرحلة طفلك المدرسية',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
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
                            // Loading Animation
                            _buildLoadingAnimation(),
                            const SizedBox(height: 20),

                            // Loading Text
                            const Text(
                              'جاري التحميل...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
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
