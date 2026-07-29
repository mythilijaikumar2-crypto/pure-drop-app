import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF1DAEFF); // Electric Aqua Blue
  static const Color primaryDark = Color(0xFF0066CC); // Deep Water Blue
  static const Color primaryLight = Color(0xFFE5F7FF); // Soft Ice Tint
  
  static const Color secondary = Color(0xFF0066CC);
  static const Color accent = Color(0xFF00E5FF);

  // Background & Surface
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Inventory & Can Status Colors
  static const Color filledCans = Color(0xFF0EA5E9);
  static const Color emptyCans = Color(0xFF64748B);
  static const Color damagedCans = Color(0xFFEF4444);
  static const Color customerBalance = Color(0xFF8B5CF6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1DAEFF), Color(0xFF0066CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
