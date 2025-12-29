// app_theme.dart
// Modern Calm Tech design system for Hospital Appointment App
// 2025 aesthetic with soft medical blue, mint green, and clean white

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CALM TECH COLOR PALETTE
// Professional, trustworthy, and stress-reducing colors for patients
// ═══════════════════════════════════════════════════════════════════════════

class CalmColors {
  // Primary Colors
  static const Color calmBlue = Color(0xFFE3F2FD);      // Soft medical blue background
  static const Color medicalBlue = Color(0xFF1976D2);   // Primary accent, buttons
  static const Color deepBlue = Color(0xFF0D47A1);      // Headers, emphasis
  
  // Secondary Colors
  static const Color mintGreen = Color(0xFFA8E6CF);     // Success states, secondary accent
  static const Color softMint = Color(0xFFE8F5E9);      // Light mint background
  static const Color tealAccent = Color(0xFF26A69A);    // Alternative accent
  
  // Alert Colors
  static const Color emergencyRed = Color(0xFFFF6B6B);  // Emergency card, alerts
  static const Color emergencyLight = Color(0xFFFFEBEE);// Emergency background
  static const Color warningOrange = Color(0xFFFFB74D); // Warnings
  
  // Neutral Colors
  static const Color pureWhite = Color(0xFFFFFFFF);     // Card backgrounds
  static const Color softGray = Color(0xFFF5F7FA);      // App background
  static const Color borderGray = Color(0xFFE0E6ED);    // Card borders
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);   // Primary text
  static const Color textSecondary = Color(0xFF7F8C8D); // Secondary text
  static const Color textMuted = Color(0xFFBDC3C7);     // Muted text, placeholders
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [medicalBlue, Color(0xFF42A5F5)],
  );
  
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintGreen, Color(0xFF81C784)],
  );
  
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emergencyRed, Color(0xFFEF5350)],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// Clean, modern, and highly readable font styles
// ═══════════════════════════════════════════════════════════════════════════

class CalmTextStyles {
  // Headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: CalmColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: CalmColors.textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: CalmColors.textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CalmColors.textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: CalmColors.textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: CalmColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: CalmColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: CalmColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: CalmColors.textMuted,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CalmColors.textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CalmColors.textSecondary,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SPACING & SIZING TOKENS
// Consistent spacing throughout the app
// ═══════════════════════════════════════════════════════════════════════════

class CalmSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class CalmRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 100.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// SHADOWS
// Soft, subtle shadows for depth
// ═══════════════════════════════════════════════════════════════════════════

class CalmShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: CalmColors.textPrimary.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: CalmColors.textPrimary.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: CalmColors.textPrimary.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: CalmColors.medicalBlue.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME DATA
// Complete Flutter ThemeData for the app
// ═══════════════════════════════════════════════════════════════════════════

class CalmTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: CalmColors.medicalBlue,
      scaffoldBackgroundColor: CalmColors.softGray,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: CalmColors.medicalBlue,
        secondary: CalmColors.mintGreen,
        surface: CalmColors.pureWhite,
        error: CalmColors.emergencyRed,
        onPrimary: CalmColors.pureWhite,
        onSecondary: CalmColors.textPrimary,
        onSurface: CalmColors.textPrimary,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: CalmColors.pureWhite,
        foregroundColor: CalmColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CalmColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: CalmColors.textPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: CalmColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CalmRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CalmColors.medicalBlue,
          foregroundColor: CalmColors.pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: CalmSpacing.md,
            horizontal: CalmSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CalmRadius.lg),
          ),
          textStyle: CalmTextStyles.buttonText,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CalmColors.medicalBlue,
          textStyle: CalmTextStyles.labelLarge,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CalmColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CalmSpacing.md,
          vertical: CalmSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CalmRadius.md),
          borderSide: const BorderSide(color: CalmColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CalmRadius.md),
          borderSide: const BorderSide(color: CalmColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CalmRadius.md),
          borderSide: const BorderSide(color: CalmColors.medicalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CalmRadius.md),
          borderSide: const BorderSide(color: CalmColors.emergencyRed),
        ),
        hintStyle: CalmTextStyles.bodyMedium.copyWith(
          color: CalmColors.textMuted,
        ),
        labelStyle: CalmTextStyles.labelMedium,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CalmColors.medicalBlue,
        foregroundColor: CalmColors.pureWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CalmRadius.lg),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CalmColors.pureWhite,
        selectedItemColor: CalmColors.medicalBlue,
        unselectedItemColor: CalmColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: CalmColors.borderGray,
        thickness: 1,
        space: CalmSpacing.md,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: CalmColors.textSecondary,
        size: 24,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CalmColors.medicalBlue,
        linearTrackColor: CalmColors.calmBlue,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CalmColors.textPrimary,
        contentTextStyle: CalmTextStyles.bodyMedium.copyWith(
          color: CalmColors.pureWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CalmRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: CalmColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CalmRadius.xl),
        ),
        titleTextStyle: CalmTextStyles.headlineMedium,
        contentTextStyle: CalmTextStyles.bodyLarge,
      ),
    );
  }
}
