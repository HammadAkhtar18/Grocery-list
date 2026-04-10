// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/grocery_item_model.dart';
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/domain/repositories/pantry_repository.dart';
import '../bloc/grocery_lists_bloc.dart';
import '../bloc/grocery_lists_event.dart';

/// Premium bottom sheet for adding items to a grocery list
class AddItemSheet extends StatefulWidget {
  final String groceryListId;
  final String? initialBarcode;
  final PantryRepository pantryRepository;
  final String failureMessage;

  AddItemSheet({
    super.key,
    required this.groceryListId,
    this.initialBarcode,
    PantryRepository? pantryRepository,
    this.failureMessage = 'Failed to add item to list',
  }) : pantryRepository = pantryRepository ?? PantryRepositoryImpl();

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedCategory = AppConstants.categories.first;
  String _selectedUnit = AppConstants.units.first;
  PantryItemModel? _duplicateItem;
  bool _isCheckingDuplicate = false;
  bool _isSubmitting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _valueOrDefault(String value, List<String> options) {
    if (options.isEmpty) {
      return value;
    }
    return options.contains(value) ? value : options.first;
  }

  /// Debounced name change handler - waits 300ms before checking
  void _onNameChanged() {
    _debounceTimer?.cancel();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) setState(() => _duplicateItem = null);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), _checkDuplicate);
  }

  /// Real-time duplicate check using direct repository call
  Future<void> _checkDuplicate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (mounted) setState(() => _isCheckingDuplicate = true);

    try {
      final duplicate = await widget.pantryRepository.checkDuplicate(
        name,
        widget.initialBarcode,
      );
      if (mounted) {
        setState(() {
          _duplicateItem = duplicate;
          _isCheckingDuplicate = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _duplicateItem = null;
          _isCheckingDuplicate = false;
        });
      }
    }
  }

  Future<void> _submitItem({bool forceAdd = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    // If duplicate found and not forcing, show confirmation
    if (_duplicateItem != null && !forceAdd) {
      _showDuplicateConfirmation();
      return;
    }

    final item = GroceryItemModel(
      id: '', // Will be set by bloc
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: double.tryParse(_quantityController.text) ?? 1,
      unit: _selectedUnit,
      barcode: widget.initialBarcode,
      isInPantry: _duplicateItem != null,
    );

    final completer = Completer<void>();

    if (mounted) {
      setState(() => _isSubmitting = true);
    }

    context.read<GroceryListsBloc>().add(
          AddItemToList(
            widget.groceryListId,
            item,
            completer: completer,
          ),
        );

    try {
      await completer.future;
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        widget.failureMessage,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showDuplicateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Already in Pantry'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have "${_duplicateItem!.name}" in your pantry:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: AppColors.warning),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_duplicateItem!.quantity} ${_duplicateItem!.unit}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Location: ${_duplicateItem!.location}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Do you still want to add this to your shopping list?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitItem(forceAdd: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Add Item',
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Duplicate warning banner
                if (_duplicateItem != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Already in Pantry',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_duplicateItem!.quantity} ${_duplicateItem!.unit} in ${_duplicateItem!.location}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Name field
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., Milk, Eggs, Bread',
                    prefixIcon: const Icon(Icons.edit_rounded),
                    counterText: '',
                    suffixIcon: _isCheckingDuplicate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity and Unit row
                Row(
                  children: [
                    // Quantity field
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          prefixIcon: Icon(Icons.numbers_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final num = double.tryParse(value);
                          if (num == null || num <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Unit dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value:
                            _valueOrDefault(_selectedUnit, AppConstants.units),
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.scale_rounded),
                        ),
                        items: AppConstants.units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _valueOrDefault(
                      _selectedCategory, AppConstants.categories),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: AppConstants.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            CategoryIcons.getIcon(cat),
                            size: 18,
                            color: CategoryIcons.getColor(cat),
                          ),
                          const SizedBox(width: 12),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Add button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (_duplicateItem != null
                                ? AppColors.warning
                                : AppColors.primary)
                            .withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitItem(),
                    icon: Icon(
                      _isSubmitting
                          ? Icons.hourglass_top_rounded
                          : _duplicateItem != null
                              ? Icons.add_alert_rounded
                              : Icons.add_shopping_cart_rounded,
                    ),
                    label: Text(
                      _isSubmitting
                          ? 'Adding...'
                          : _duplicateItem != null
                              ? 'Add Anyway'
                              : 'Add to List',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _duplicateItem != null
                          ? AppColors.warning
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
