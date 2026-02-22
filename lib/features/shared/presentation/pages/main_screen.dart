import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../grocery_list/presentation/bloc/grocery_bloc.dart';
import '../../../grocery_list/presentation/bloc/grocery_event.dart';
import '../../../grocery_list/presentation/pages/lists_page.dart';
import '../../../pantry/presentation/bloc/pantry_bloc.dart';
import '../../../pantry/presentation/bloc/pantry_event.dart';
import '../../../pantry/presentation/pages/pantry_page.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium main screen with animated bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ListsPage(),
    PantryPage(),
    ScannerPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<GroceryBloc>().add(LoadLists());
    context.read<PantryBloc>().add(LoadPantry());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
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
                  isActive: _currentIndex == 0,
                  color: AppColors.primary,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Pantry',
                  isActive: _currentIndex == 1,
                  color: AppColors.secondary,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  icon: Icons.qr_code_scanner_outlined,
                  activeIcon: Icons.qr_code_scanner_rounded,
                  label: 'Scan',
                  isActive: _currentIndex == 2,
                  color: AppColors.accent,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: _currentIndex == 3,
                  color: AppColors.textSecondary,
                  onTap: () => _onNavTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    // Reload data when switching tabs
    if (index == 0) {
      context.read<GroceryBloc>().add(LoadLists());
    } else if (index == 1) {
      context.read<PantryBloc>().add(LoadPantry());
    }
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
