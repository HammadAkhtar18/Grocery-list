import 'package:equatable/equatable.dart';

class AppSettingsState extends Equatable {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final DateTime? lastPantryNotificationAt;
  final DateTime? lastBackupAt;

  const AppSettingsState({
    this.isDarkMode = false,
    this.notificationsEnabled = false,
    this.lastPantryNotificationAt,
    this.lastBackupAt,
  });

  AppSettingsState copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    DateTime? lastPantryNotificationAt,
    bool clearLastPantryNotificationAt = false,
    DateTime? lastBackupAt,
    bool clearLastBackupAt = false,
  }) {
    return AppSettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastPantryNotificationAt: clearLastPantryNotificationAt
          ? null
          : (lastPantryNotificationAt ?? this.lastPantryNotificationAt),
      lastBackupAt:
          clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        notificationsEnabled,
        lastPantryNotificationAt,
        lastBackupAt,
      ];
}
