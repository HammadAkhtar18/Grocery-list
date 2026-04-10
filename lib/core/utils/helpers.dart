import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';

/// Utility helper functions
class Helpers {
  Helpers._();

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, y \u2022 h:mm a').format(date);
  }

  /// Get days until expiration
  static int daysUntilExpiration(DateTime expirationDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration =
        DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
    return expiration.difference(today).inDays;
  }

  /// Get expiration status
  static ExpirationStatus getExpirationStatus(DateTime? expirationDate) {
    if (expirationDate == null) return ExpirationStatus.none;

    final days = daysUntilExpiration(expirationDate);

    if (days < 0) return ExpirationStatus.expired;
    if (days <= 3) return ExpirationStatus.expiringSoon;
    if (days <= 7) return ExpirationStatus.expiringWeek;
    return ExpirationStatus.ok;
  }

  /// Get expiration color based on status
  static Color getExpirationColor(ExpirationStatus status) {
    switch (status) {
      case ExpirationStatus.expired:
        return AppColors.error;
      case ExpirationStatus.expiringSoon:
        return AppColors.warning;
      case ExpirationStatus.expiringWeek:
        return Colors.amber;
      case ExpirationStatus.ok:
        return AppColors.primary;
      case ExpirationStatus.none:
        return AppColors.textSecondary;
    }
  }

  /// Get expiration text
  static String getExpirationText(DateTime? expirationDate) {
    if (expirationDate == null) return 'No expiration';

    final days = daysUntilExpiration(expirationDate);

    if (days < 0) return 'Expired ${-days} day(s) ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${formatDate(expirationDate)}';
  }

  /// Check if item is low stock
  static bool isLowStock(double quantity, double? threshold) {
    if (threshold == null) return false;
    return quantity <= threshold;
  }

  /// Generate unique ID
  static String generateId() {
    return const Uuid().v4();
  }

  /// Show snackbar
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Expiration status enum
enum ExpirationStatus {
  none,
  ok,
  expiringWeek,
  expiringSoon,
  expired,
}
