import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final savedUsername = HiveService.getData(AppConstants.authBoxName, 'savedUsername', defaultValue: '');
    final savedPassword = HiveService.getData(AppConstants.authBoxName, 'savedPassword', defaultValue: '');

    if (savedUsername.toString().isNotEmpty) {
      _usernameController.text = savedUsername.toString();
    }
    if (savedPassword.toString().isNotEmpty) {
      _passwordController.text = savedPassword.toString();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).loginWithUsernamePassword(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            rememberMe: _rememberMe,
          );

      if (mounted) {
        final authState = ref.read(authProvider);
        if (success && authState.isAuthenticated) {
          if (authState.user?.role == UserRole.admin) {
            context.go('/dashboard');
          } else {
            context.go('/delivery');
          }
        } else if (authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(authState.errorMessage!)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }


  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To reset your password, please contact the Pure Drop Aqua Administrator.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Admin Desk: +91 98765 43210', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE5F7FF), Color(0xFFF7FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: CustomCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Official Pure Drop Aqua Logo
                      const AppLogo(size: 230).animate().scale(duration: 400.ms),

                      const SizedBox(height: 20),

                      // Username Input Field
                      CustomTextField(
                        label: 'Username',
                        hint: 'Enter your ERP username (min 4 chars)',
                        controller: _usernameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Username is required';
                          if (v.trim().length < 4) return 'Username must be at least 4 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Input Field with Eye Toggle
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter password (min 6 chars)',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Password is required';
                          if (v.trim().length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Remember Me & Forgot Password Row
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? true);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Remember Me', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              // Remove excess horizontal padding that causes overflow
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Submit Login Button
                      CustomButton(
                        label: 'Login',
                        icon: Icons.login_rounded,
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                      ),


                    ],
                  ), // Column
                ), // Form
              ), // CustomCard
            ), // ConstrainedBox
          ), // SingleChildScrollView
        ), // Center
      ), // Container
    ), // SafeArea
    );
  }
}
