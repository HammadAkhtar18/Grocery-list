import 'package:flutter/material.dart';

/// Premium application color palette with vibrant colors
class AppColors {
  AppColors._();

  // Primary gradient colors
  static const Color primary = Color(0xFF00C851);        // Vibrant Green
  static const Color primaryDark = Color(0xFF00A040);
  static const Color primaryLight = Color(0xFF8EE5A1);
  static const Color primaryGradientStart = Color(0xFF00C851);
  static const Color primaryGradientEnd = Color(0xFF4ECDC4);   // Teal

  // Secondary gradient colors  
  static const Color secondary = Color(0xFF667EEA);      // Purple Blue
  static const Color secondaryGradientStart = Color(0xFF667EEA);
  static const Color secondaryGradientEnd = Color(0xFF764BA2);

  // Accent colors
  static const Color accent = Color(0xFFFF6B6B);         // Coral
  static const Color accentYellow = Color(0xFFFFD93D);   // Bright Yellow
  static const Color accentPink = Color(0xFFFF8E8E);     // Soft Pink
  static const Color accentPurple = Color(0xFFA855F7);   // Purple

  // Status colors
  static const Color warning = Color(0xFFFF9500);        // Orange
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF3B30);          // Red
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF34C759);        // Green
  static const Color successLight = Color(0xFFE8F5E9);

  // Background colors
  static const Color background = Color(0xFFF8FAFC);     // Light blue gray
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);    // Slate 800
  static const Color textSecondary = Color(0xFF64748B);  // Slate 500
  static const Color textHint = Color(0xFF94A3B8);       // Slate 400

  // Category colors
  static const categoryColors = {
    'Produce': Color(0xFF22C55E),         // Green
    'Dairy': Color(0xFF3B82F6),           // Blue
    'Meat': Color(0xFFEF4444),            // Red
    'Bakery': Color(0xFFF59E0B),          // Amber
    'Frozen': Color(0xFF06B6D4),          // Cyan
    'Beverages': Color(0xFF8B5CF6),       // Violet
    'Snacks': Color(0xFFEC4899),          // Pink
    'Household': Color(0xFF6366F1),       // Indigo
    'Personal Care': Color(0xFFF97316),   // Orange
    'Other': Color(0xFF64748B),           // Slate
  };
}

/// Gradient definitions
class AppGradients {
  AppGradients._();

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryGradientStart, AppColors.secondaryGradientEnd],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF64B5F6)],
  );

  static const LinearGradient cardShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );
}

/// Application theme configuration with premium styling
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.cardBackground,
        shadowColor: Colors.black.withAlpha(20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        prefixIconColor: AppColors.textSecondary,
        hintStyle: TextStyle(color: AppColors.textHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withAlpha(100),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: AppColors.primary, width: 2),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        side: BorderSide(color: AppColors.textSecondary, width: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        indicatorColor: AppColors.primary.withAlpha(30),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.surfaceVariant,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Icon mapping for categories
class CategoryIcons {
  CategoryIcons._();

  static IconData getIcon(String category) {
    return _categoryIcons[category] ?? Icons.category;
  }

  static Color getColor(String category) {
    return AppColors.categoryColors[category] ?? AppColors.textSecondary;
  }

  static const _categoryIcons = {
    'Produce': Icons.eco,
    'Dairy': Icons.water_drop,
    'Meat': Icons.restaurant,
    'Bakery': Icons.bakery_dining,
    'Frozen': Icons.ac_unit,
    'Beverages': Icons.local_cafe,
    'Snacks': Icons.cookie,
    'Household': Icons.cleaning_services,
    'Personal Care': Icons.spa,
    'Other': Icons.category,
  };
}
