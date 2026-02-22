import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'grocery_item_model.g.dart';

/// Grocery item model for shopping lists
@HiveType(typeId: 1)
class GroceryItemModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final bool isChecked;

  @HiveField(6)
  final bool isInPantry;

  @HiveField(7)
  final String? barcode;

  const GroceryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    this.isInPantry = false,
    this.barcode,
  });

  /// Create a copy with updated fields
  GroceryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    bool? isChecked,
    bool? isInPantry,
    String? barcode,
  }) {
    return GroceryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      isInPantry: isInPantry ?? this.isInPantry,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  List<Object?> get props => [id, name, category, quantity, unit, isChecked, isInPantry, barcode];
}
