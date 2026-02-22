import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/grocery_item_model.dart';
import '../bloc/grocery_bloc.dart';
import '../bloc/grocery_event.dart';
import '../bloc/grocery_state.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/duplicate_warning_badge.dart';

/// Premium list detail page with gradient header
class ListDetailPage extends StatefulWidget {
  final String listId;

  const ListDetailPage({super.key, required this.listId});

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<GroceryBloc>().add(LoadListDetails(widget.listId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroceryBloc, GroceryState>(
      buildWhen: (previous, current) {
        // Only rebuild for states relevant to the detail page
        return current is GroceryListDetailLoaded ||
            current is GroceryLoading ||
            current is GroceryError;
      },
      builder: (context, state) {
        if (state is GroceryLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is GroceryError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is GroceryListDetailLoaded) {
          return _buildContent(context, state);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('List')),
          body: const Center(child: Text('List not found')),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, GroceryListDetailLoaded state) {
    final list = state.list;
    final items = state.shoppingMode
        ? list.items.where((item) => !item.isInPantry).toList()
        : list.items;

    // Group items by category
    final groupedItems = <String, List<GroceryItemModel>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<GroceryBloc>().add(LoadLists());
        }
      },
      child: Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient app bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () {
                context.read<GroceryBloc>().add(LoadLists());
                Navigator.pop(context);
              },
            ),
            actions: [
              // Shopping mode toggle
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    context.read<GroceryBloc>().add(ToggleShoppingMode());
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.shoppingMode
                          ? Colors.white
                          : Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      state.shoppingMode
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: state.shoppingMode ? AppColors.primary : Colors.white,
                    ),
                  ),
                  tooltip: state.shoppingMode
                      ? 'Show all items'
                      : 'Shopping mode',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(70, 0, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.white.withAlpha(200),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${list.checkedCount}/${list.totalCount} completed',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shopping mode banner
          if (state.shoppingMode)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppGradients.oceanGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shopping mode: Hiding items already in pantry',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Items list
          if (items.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context, state.shoppingMode),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildGroupedItems(context, groupedItems, state),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemSheet(context, widget.listId),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
        ),
      ),
      ),
    );
  }

  List<Widget> _buildGroupedItems(
    BuildContext context,
    Map<String, List<GroceryItemModel>> groupedItems,
    GroceryListDetailLoaded state,
  ) {
    final categories = groupedItems.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final category in categories) {
      final categoryItems = groupedItems[category]!;
      final categoryColor = CategoryIcons.getColor(category);
      final categoryIcon = CategoryIcons.getIcon(category);

      // Category header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon, size: 18, color: categoryColor),
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${categoryItems.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Items
      for (int i = 0; i < categoryItems.length; i++) {
        widgets.add(_buildItemTile(context, categoryItems[i], state, i));
      }
    }

    return widgets;
  }

  Widget _buildEmptyState(BuildContext context, bool shoppingMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: shoppingMode
                    ? AppGradients.oceanGradient
                    : AppGradients.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (shoppingMode ? AppColors.secondary : AppColors.primary)
                        .withAlpha(60),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                shoppingMode ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              shoppingMode ? 'All done!' : 'No Items Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              shoppingMode
                  ? 'All items are in your pantry!\nYou\'re fully stocked 🎉'
                  : 'Add items to start\nbuilding your shopping list',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    GroceryItemModel item,
    GroceryListDetailLoaded state,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Slidable(
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  context.read<GroceryBloc>().add(
                        DeleteItem(widget.listId, item.id),
                      );
                  Helpers.showSnackBar(context, 'Item deleted');
                },
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
              onTap: () {
                context.read<GroceryBloc>().add(
                      ToggleItem(widget.listId, item.id),
                    );
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? AppColors.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: item.isChecked
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Animated checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: item.isChecked
                            ? const LinearGradient(
                                colors: [AppColors.success, Color(0xFF34D399)],
                              )
                            : null,
                        color: item.isChecked ? null : Colors.transparent,
                        border: item.isChecked
                            ? null
                            : Border.all(color: AppColors.textSecondary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.isChecked
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (item.isInPantry) ...[
                                const SizedBox(width: 8),
                                const DuplicateWarningBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, String listId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddItemSheet(listId: listId),
      ),
    );
  }
}
