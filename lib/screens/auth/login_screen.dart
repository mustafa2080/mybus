import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final UserModel? user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        _navigateBasedOnUserType(user.userType);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // معالجة خاصة لخطأ PigeonUserDetails
        if (errorMessage.contains('PigeonUserDetails') ||
            errorMessage.contains('List<Object?>')) {
          errorMessage = 'خطأ مؤقت في النظام. يرجى المحاولة مرة أخرى.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateBasedOnUserType(UserType userType) {
    // Add delay to prevent navigation loops
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'باصي',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Login Button
                CustomButton(
                  text: 'تسجيل الدخول',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),


                
                // Forgot Password
                TextButton(
                  onPressed: () {
                    context.push('/forgot-password');
                  },
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟ ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
