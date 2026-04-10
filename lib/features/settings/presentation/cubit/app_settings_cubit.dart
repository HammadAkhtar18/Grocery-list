import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  static const _darkModeKey = 'dark_mode_enabled';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _lastPantryNotificationKey = 'last_pantry_notification_at';
  static const _lastBackupKey = 'last_backup_at';

  final Box<dynamic> _box;

  AppSettingsCubit({Box<dynamic>? box})
      : _box = box ?? Hive.box<dynamic>(AppConstants.appSettingsBox),
        super(_loadInitialState(
            box ?? Hive.box<dynamic>(AppConstants.appSettingsBox)));

  static AppSettingsState _loadInitialState(Box<dynamic> box) {
    return AppSettingsState(
      isDarkMode: box.get(_darkModeKey, defaultValue: false) as bool? ?? false,
      notificationsEnabled:
          box.get(_notificationsEnabledKey, defaultValue: false) as bool? ??
              false,
      lastPantryNotificationAt: _readDateTime(
        box.get(_lastPantryNotificationKey),
      ),
      lastBackupAt: _readDateTime(
        box.get(_lastBackupKey),
      ),
    );
  }

  static DateTime? _readDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _box.put(_darkModeKey, enabled);
    emit(state.copyWith(isDarkMode: enabled));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(_notificationsEnabledKey, enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  bool shouldSendPantryDigest(DateTime now) {
    if (!state.notificationsEnabled) return false;

    final lastSent = state.lastPantryNotificationAt;
    if (lastSent == null) return true;

    return lastSent.year != now.year ||
        lastSent.month != now.month ||
        lastSent.day != now.day;
  }

  Future<void> markPantryDigestSent(DateTime when) async {
    await _box.put(_lastPantryNotificationKey, when.toIso8601String());
    emit(state.copyWith(lastPantryNotificationAt: when));
  }

  Future<void> markBackupCreated(DateTime when) async {
    await _box.put(_lastBackupKey, when.toIso8601String());
    emit(state.copyWith(lastBackupAt: when));
  }
}
