import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/pantry_item_model.dart';
import '../bloc/pantry_bloc.dart';
import '../bloc/pantry_event.dart';
import '../bloc/pantry_state.dart';
import '../widgets/add_pantry_item_sheet.dart';

/// Premium pantry screen with modern design
class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final List<String?> _tabs = [null, ...AppConstants.locations];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final location = _tabs[_tabController.index];
      context.read<PantryBloc>().add(FilterByLocation(location));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Gradient hero header
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.secondary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.secondaryGradient,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(10),
                          ),
                        ),
                      ),
                      // Content
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
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
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Pantry',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        'Track your inventory',
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(context),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: AppColors.secondary,
                    indicatorWeight: 3,
                    labelColor: AppColors.secondary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: _tabs.map((loc) {
                      return Tab(
                        text: loc ?? 'All',
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Search bar (pinned in header)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surfaceFor(context),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pantry...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<PantryBloc>()
                                  .add(const SearchPantry(''));
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariantFor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    context.read<PantryBloc>().add(SearchPantry(value));
                    setState(() {});
                  },
                ),
              ),
            ),
          ];
        },
        body: Container(
          color: AppColors.surfaceFor(context),
          child: BlocBuilder<PantryBloc, PantryState>(
            builder: (context, state) {
              if (state is PantryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PantryError) {
                return _buildErrorState(context, state.message);
              }

              if (state is PantryLoaded) {
                if (state.filteredItems.isEmpty) {
                  return _buildEmptyState(context, state);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: state.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = state.filteredItems[index];
                    return _PantryItemCard(
                      item: item,
                      index: index,
                      onTap: () => _showEditItemSheet(context, item),
                      onDelete: () {
                        context
                            .read<PantryBloc>()
                            .add(DeletePantryItem(item.id));
                        Helpers.showSnackBar(context, 'Item deleted');
                      },
                    );
                  },
                );
              }

              return _buildEmptyState(context, null);
            },
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.secondaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildEmptyState(BuildContext context, PantryLoaded? state) {
    final hasSearch = state?.searchQuery.isNotEmpty ?? false;
    final hasFilter = state?.selectedLocation != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppGradients.secondaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(60),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  hasSearch || hasFilter
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              hasSearch || hasFilter ? 'No items found' : 'Pantry is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch || hasFilter
                  ? 'Try a different search or filter'
                  : 'Add items to track your\ninventory and expiration dates',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (!hasSearch && !hasFilter) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAddItemSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
          ),
          const SizedBox(height: 24),
          Text(message, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<PantryBloc>().add(LoadPantry()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const AddPantryItemSheet(),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context, PantryItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddPantryItemSheet(existingItem: item),
      ),
    );
  }
}

/// Premium pantry item card
class _PantryItemCard extends StatelessWidget {
  final PantryItemModel item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PantryItemCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final expirationStatus = Helpers.getExpirationStatus(item.expirationDate);
    final expirationColor = Helpers.getExpirationColor(expirationStatus);
    final categoryColor = CategoryIcons.getColor(item.category);
    final categoryIcon = CategoryIcons.getIcon(item.category);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Slidable(
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => onDelete(),
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Delete',
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundFor(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowFor(context),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Category icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: categoryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(categoryIcon,
                              size: 22, color: categoryColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getLocationIcon(item.location),
                                    size: 14,
                                    color: AppColors.textSecondaryFor(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit} \u2022 ${item.location}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Status badges (only show if any apply)
                    if (item.expirationDate != null || item.isLowStock) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.expirationDate != null)
                            _StatusBadge(
                              icon: Icons.schedule_rounded,
                              text: Helpers.getExpirationText(
                                  item.expirationDate),
                              color: expirationColor,
                            ),
                          if (item.isLowStock)
                            _StatusBadge(
                              icon: Icons.warning_amber_rounded,
                              text: 'Low stock',
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location) {
      case 'Fridge':
        return Icons.kitchen_rounded;
      case 'Freezer':
        return Icons.ac_unit_rounded;
      case 'Pantry':
        return Icons.shelves;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
