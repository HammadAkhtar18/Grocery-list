import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'pantry_item_model.g.dart';

/// Pantry item model for inventory tracking
@HiveType(typeId: 2)
class PantryItemModel extends Equatable {
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
  final String location; // Fridge, Freezer, Pantry, Other

  @HiveField(6)
  final DateTime? expirationDate;

  @HiveField(7)
  final DateTime addedDate;

  @HiveField(8)
  final double? lowStockThreshold;

  @HiveField(9)
  final String? barcode;

  const PantryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.location,
    this.expirationDate,
    required this.addedDate,
    this.lowStockThreshold,
    this.barcode,
  });

  /// Check if item is low stock
  bool get isLowStock {
    if (lowStockThreshold == null) return false;
    return quantity <= lowStockThreshold!;
  }

  /// Create a copy with updated fields
  PantryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    String? location,
    DateTime? expirationDate,
    DateTime? addedDate,
    double? lowStockThreshold,
    String? barcode,
  }) {
    return PantryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      expirationDate: expirationDate ?? this.expirationDate,
      addedDate: addedDate ?? this.addedDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        quantity,
        unit,
        location,
        expirationDate,
        addedDate,
        lowStockThreshold,
        barcode,
      ];
}
