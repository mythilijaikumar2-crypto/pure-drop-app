import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
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
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');

  bool _rememberMe = true;
  bool _obscurePassword = true;
  UserRole _selectedRoleTab = UserRole.admin;

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

  void _fillDemoAdmin() {
    setState(() {
      _selectedRoleTab = UserRole.admin;
      _usernameController.text = 'admin';
      _passwordController.text = 'admin123';
    });
  }

  void _fillDemoDriver() {
    setState(() {
      _selectedRoleTab = UserRole.deliveryBoy;
      _usernameController.text = 'driver';
      _passwordController.text = 'driver123';
    });
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
                      const AppLogo(size: 160).animate().scale(duration: 400.ms),

                      const SizedBox(height: 16),
                      const Text(
                        'Distribution & Operations ERP',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),

                      // Quick Role Selector Switch
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _fillDemoAdmin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedRoleTab == UserRole.admin
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: _selectedRoleTab == UserRole.admin
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Admin Login',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _selectedRoleTab == UserRole.admin
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _fillDemoDriver,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedRoleTab == UserRole.deliveryBoy
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delivery_dining,
                                        color: _selectedRoleTab == UserRole.deliveryBoy
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Driver Login',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _selectedRoleTab == UserRole.deliveryBoy
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        label: _selectedRoleTab == UserRole.admin ? 'Login as Admin' : 'Login as Delivery Driver',
                        icon: Icons.login_rounded,
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                      ),

                      const SizedBox(height: 16),

                      // Quick Demo Helpers Footer
                      // Using Wrap so chips flow onto the next line on narrow screens
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.admin_panel_settings, size: 14, color: AppColors.primary),
                            label: const Text('Admin Demo', style: TextStyle(fontSize: 11)),
                            onPressed: _fillDemoAdmin,
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.delivery_dining, size: 14, color: AppColors.info),
                            label: const Text('Driver Demo', style: TextStyle(fontSize: 11)),
                            onPressed: _fillDemoDriver,
                          ),
                        ],
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
