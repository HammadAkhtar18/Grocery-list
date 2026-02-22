import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'grocery_item_model.dart';

part 'grocery_list_model.g.dart';

/// Grocery list model containing a list of items
@HiveType(typeId: 0)
class GroceryListModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<GroceryItemModel> items;

  const GroceryListModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
  });

  /// Get count of checked items
  int get checkedCount => items.where((item) => item.isChecked).length;

  /// Get total item count
  int get totalCount => items.length;

  /// Get progress ratio (0.0 to 1.0)
  double get progress => totalCount > 0 ? checkedCount / totalCount : 0.0;

  /// Create a copy with updated fields
  GroceryListModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<GroceryItemModel>? items,
  }) {
    return GroceryListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, items];
}
