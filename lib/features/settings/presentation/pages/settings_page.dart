import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_handling.dart';
import '../../../grocery_list/data/models/grocery_list_model.dart';
import '../../../grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import '../../../grocery_list/presentation/bloc/grocery_lists_event.dart'
    as grocery_events;
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/presentation/bloc/pantry_bloc.dart';
import '../../../pantry/presentation/bloc/pantry_event.dart' as pantry_events;
import '../cubit/app_settings_cubit.dart';
import '../cubit/app_settings_state.dart';

/// Premium settings page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.textSecondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.textPrimary,
                      AppColors.textSecondary,
                    ],
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Settings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'Customize your experience',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
            ),
          ),

          // Settings content
          SliverToBoxAdapter(
            child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
              builder: (context, settings) {
                final backupSubtitle = settings.lastBackupAt == null
                    ? 'Create and share a JSON backup'
                    : 'Last export ${DateFormat.yMMMd().add_jm().format(settings.lastBackupAt!)}';

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(context, settings),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'EXPERIENCE'),
                      const SizedBox(height: 12),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: AppColors.accent,
                            title: 'Smart Notifications',
                            subtitle: settings.notificationsEnabled
                                ? 'Daily pantry alerts are active'
                                : 'Get alerts for low stock and expiring items',
                            trailing: Switch(
                              value: settings.notificationsEnabled,
                              onChanged: (value) =>
                                  _toggleNotifications(context, value),
                              activeThumbColor: AppColors.primary,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.dark_mode_rounded,
                            iconColor: AppColors.secondary,
                            title: 'Dark Mode',
                            subtitle: settings.isDarkMode
                                ? 'Premium dark appearance enabled'
                                : 'Switch to a rich low-light theme',
                            trailing: Switch(
                              value: settings.isDarkMode,
                              onChanged: (value) => context
                                  .read<AppSettingsCubit>()
                                  .setDarkMode(value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'DATA'),
                      const SizedBox(height: 12),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.ios_share_rounded,
                            iconColor: AppColors.primary,
                            title: 'Export Backup',
                            subtitle: backupSubtitle,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onTap: () => _exportBackup(context),
                          ),
                          _SettingsTile(
                            icon: Icons.delete_sweep_rounded,
                            iconColor: AppColors.error,
                            title: 'Clear All Data',
                            subtitle: 'Remove all lists and pantry items',
                            onTap: () => _showClearDataDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'ABOUT'),
                      const SizedBox(height: 12),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.info_rounded,
                            iconColor: AppColors.secondary,
                            title: 'About',
                            subtitle: 'Version, signing and app information',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Grocery & Pantry',
                                applicationVersion: '1.0.0',
                                applicationLegalese:
                                    '\u00A9 ${DateTime.now().year} Grocery & Pantry',
                                applicationIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          _SettingsTile(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: AppColors.accentPurple,
                            title: 'Design Note',
                            subtitle:
                                'Premium gradients, dark theme, and smart utility features are now live',
                            trailing: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, AppSettingsState settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grocery & Pantry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.isDarkMode
                          ? 'Dark mode tuned for nighttime planning'
                          : 'Bright, polished surfaces for everyday planning',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(
                icon: settings.notificationsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                label:
                    settings.notificationsEnabled ? 'Alerts On' : 'Alerts Off',
              ),
              _HeroBadge(
                icon: settings.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                label: settings.isDarkMode ? 'Dark Theme' : 'Light Theme',
              ),
              const _HeroBadge(
                icon: Icons.workspace_premium_rounded,
                label: 'Premium UI',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Clear All Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your shopping lists and pantry items. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearAllData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    bool clearedSuccessfully = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Clearing data...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final groceryBox =
          Hive.box<GroceryListModel>(AppConstants.groceryListsBox);
      final pantryBox = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);

      await groceryBox.clear();
      await pantryBox.clear();

      if (!context.mounted) return;

      context.read<GroceryListsBloc>().add(grocery_events.LoadLists());
      context.read<PantryBloc>().add(pantry_events.LoadPantry());
      clearedSuccessfully = true;
    } catch (e, stackTrace) {
      appLog('SettingsPage._clearAllData error: $e\n$stackTrace');
      errorMessage = userFriendlyErrorMessage(e);
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clearedSuccessfully
              ? 'All data cleared successfully'
              : errorMessage ?? userFriendlyErrorMessage(Exception()),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: clearedSuccessfully ? null : AppColors.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(BuildContext context, bool enabled) async {
    final settingsCubit = context.read<AppSettingsCubit>();

    if (!enabled) {
      await settingsCubit.setNotificationsEnabled(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Smart notifications turned off'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification permission was not granted.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      await settingsCubit.setNotificationsEnabled(true);
      await NotificationService.instance.showNotificationsEnabledConfirmation();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Smart notifications enabled'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e, stackTrace) {
      appLog('SettingsPage._toggleNotifications error: $e\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final settingsCubit = context.read<AppSettingsCubit>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Preparing backup...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await BackupService.instance.exportBackup();
      await settingsCubit.markBackupCreated(DateTime.now());

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup ready to share'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e, stackTrace) {
      appLog('SettingsPage._exportBackup error: $e\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children
            .expand((child) => [
                  child,
                  if (child != children.last)
                    const Divider(height: 1, indent: 72),
                ])
            .toList(),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryFor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondaryFor(context),
          height: 1.4,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
