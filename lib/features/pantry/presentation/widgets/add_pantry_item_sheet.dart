import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/pantry_item_model.dart';
import '../bloc/pantry_bloc.dart';
import '../bloc/pantry_event.dart';

/// Premium bottom sheet for adding/editing pantry items
class AddPantryItemSheet extends StatefulWidget {
  final PantryItemModel? existingItem;
  final String? initialBarcode;

  const AddPantryItemSheet({
    super.key,
    this.existingItem,
    this.initialBarcode,
  });

  @override
  State<AddPantryItemSheet> createState() => _AddPantryItemSheetState();
}

class _AddPantryItemSheetState extends State<AddPantryItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _lowStockThresholdController;
  
  String _selectedCategory = AppConstants.categories.first;
  String _selectedUnit = AppConstants.units.first;
  String _selectedLocation = AppConstants.locations.first;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(text: item?.quantity.toString() ?? '1');
    _lowStockThresholdController = TextEditingController(
      text: item?.lowStockThreshold?.toString() ?? '',
    );
    
    if (item != null) {
      _selectedCategory = item.category;
      _selectedUnit = item.unit;
      _selectedLocation = item.location;
      _expirationDate = item.expirationDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final item = PantryItemModel(
      id: widget.existingItem?.id ?? '', // ID handled by repo if empty
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: double.tryParse(_quantityController.text) ?? 1,
      unit: _selectedUnit,
      location: _selectedLocation,
      expirationDate: _expirationDate,
      lowStockThreshold: double.tryParse(_lowStockThresholdController.text),
      barcode: widget.existingItem?.barcode ?? widget.initialBarcode,
      addedDate: widget.existingItem?.addedDate ?? DateTime.now(),
    );

    if (widget.existingItem != null) {
      context.read<PantryBloc>().add(UpdatePantryItem(item));
    } else {
      context.read<PantryBloc>().add(AddPantryItem(item));
    }

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                      gradient: AppGradients.secondaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.inventory_2_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isEditing ? 'Edit Item' : 'Add to Pantry',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Milk, Rice, Pasta',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity, Unit, Location row
              Row(
                children: [
                   // Quantity
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Unit
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: AppConstants.units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
                items: AppConstants.locations.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (val) => setState(() => _selectedLocation = val!),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
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
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Expiration Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _expirationDate != null 
                            ? AppColors.secondary 
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _expirationDate == null
                              ? 'Expiration Date (Optional)'
                              : DateFormat.yMMMd().format(_expirationDate!),
                          style: TextStyle(
                            color: _expirationDate != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_expirationDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () => setState(() => _expirationDate = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Low Stock Threshold
              TextFormField(
                controller: _lowStockThresholdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert Limit (Optional)',
                  hintText: 'e.g., 2',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(isEditing ? 'Save Changes' : 'Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
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
    );
  }
}
