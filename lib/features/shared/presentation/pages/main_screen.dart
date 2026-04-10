import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/services/notification_service.dart';
import '../../../grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import '../../../grocery_list/presentation/bloc/grocery_lists_event.dart';
import '../../../grocery_list/presentation/pages/lists_page.dart';
import '../../../pantry/presentation/bloc/pantry_bloc.dart';
import '../../../pantry/presentation/bloc/pantry_event.dart';
import '../../../pantry/presentation/bloc/pantry_state.dart';
import '../../../pantry/presentation/pages/pantry_page.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/cubit/app_settings_cubit.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium main screen with animated bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _listsTabIndex = 0;
  static const int _pantryTabIndex = 1;
  static const int _scanTabIndex = 2;
  static const int _settingsTabIndex = 3;

  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _nonScannerPages = const [
    ListsPage(),
    PantryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: _pageIndexForTab(_currentIndex));

    // Load initial data
    context.read<GroceryListsBloc>().add(LoadLists());
    context.read<PantryBloc>().add(LoadPantry());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PantryBloc, PantryState>(
      listener: (context, state) {
        if (state is PantryLoaded) {
          unawaited(_maybeSendPantryDigest(context, state));
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Offstage(
              offstage: _currentIndex == _scanTabIndex,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _nonScannerPages,
              ),
            ),
            if (_currentIndex == _scanTabIndex) ScannerPage(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowFor(context),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart_rounded,
                    label: 'Lists',
                    isActive: _currentIndex == _listsTabIndex,
                    color: AppColors.primary,
                    onTap: () => _onNavTap(_listsTabIndex),
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    label: 'Pantry',
                    isActive: _currentIndex == _pantryTabIndex,
                    color: AppColors.secondary,
                    onTap: () => _onNavTap(_pantryTabIndex),
                  ),
                  _NavItem(
                    icon: Icons.qr_code_scanner_outlined,
                    activeIcon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    isActive: _currentIndex == _scanTabIndex,
                    color: AppColors.accent,
                    onTap: () => _onNavTap(_scanTabIndex),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: _currentIndex == _settingsTabIndex,
                    color: AppColors.textSecondary,
                    onTap: () => _onNavTap(_settingsTabIndex),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index != _scanTabIndex && _pageController.hasClients) {
      _pageController.jumpToPage(_pageIndexForTab(index));
    }

    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }

    // Reload data when switching tabs
    if (index == _listsTabIndex) {
      context.read<GroceryListsBloc>().add(LoadLists());
    } else if (index == _pantryTabIndex) {
      context.read<PantryBloc>().add(LoadPantry());
    }
  }

  int _pageIndexForTab(int tabIndex) {
    switch (tabIndex) {
      case _listsTabIndex:
        return 0;
      case _pantryTabIndex:
        return 1;
      case _settingsTabIndex:
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _maybeSendPantryDigest(
    BuildContext context,
    PantryLoaded state,
  ) async {
    final settings = context.read<AppSettingsCubit>();
    final now = DateTime.now();

    if (!settings.state.notificationsEnabled ||
        !settings.shouldSendPantryDigest(now)) {
      return;
    }

    final expiringSoonCount = state.items.where((item) {
      final expirationDate = item.expirationDate;
      if (expirationDate == null) return false;
      final difference = expirationDate.difference(now).inDays;
      return difference <= 3;
    }).length;
    final lowStockCount = state.items.where((item) => item.isLowStock).length;

    if (expiringSoonCount == 0 && lowStockCount == 0) {
      return;
    }

    await NotificationService.instance.showPantryStatusDigest(
      expiringSoonCount: expiringSoonCount,
      lowStockCount: lowStockCount,
    );
    await settings.markPantryDigestSent(now);
  }
}

/// Animated navigation item with pill indicator
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? color : AppColors.textSecondary,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
