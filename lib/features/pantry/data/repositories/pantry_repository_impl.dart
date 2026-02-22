import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../models/pantry_item_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Hive-based implementation of the pantry repository
class PantryRepositoryImpl implements PantryRepository {
  Box<PantryItemModel>? _box;

  Future<Box<PantryItemModel>> get _pantryBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
    return _box!;
  }

  @override
  Future<List<PantryItemModel>> getAllItems() async {
    final box = await _pantryBox;
    final items = box.values.toList();
    // Sort by added date, newest first
    items.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    return items;
  }

  @override
  Future<List<PantryItemModel>> getItemsByLocation(String location) async {
    final items = await getAllItems();
    return items.where((item) => item.location == location).toList();
  }

  @override
  Future<PantryItemModel?> getItemById(String id) async {
    final box = await _pantryBox;
    try {
      return box.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addItem(PantryItemModel item) async {
    final box = await _pantryBox;
    await box.put(item.id, item);
  }

  @override
  Future<void> updateItem(PantryItemModel item) async {
    final box = await _pantryBox;
    await box.put(item.id, item);
  }

  @override
  Future<void> deleteItem(String id) async {
    final box = await _pantryBox;
    await box.delete(id);
  }

  /// Core duplicate detection logic
  /// 
  /// This is the CRITICAL feature of the app - checks if an item already
  /// exists in the pantry before adding to shopping list.
  /// 
  /// Priority:
  /// 1. Exact barcode match (if barcode provided)
  /// 2. Case-insensitive name match
  @override
  Future<PantryItemModel?> checkDuplicate(String name, String? barcode) async {
    final box = await _pantryBox;

    // First try barcode match (exact match)
    if (barcode != null && barcode.isNotEmpty) {
      for (var item in box.values) {
        if (item.barcode != null && item.barcode == barcode) {
          return item;
        }
      }
    }

    // Then try name match (case-insensitive, trimmed)
    final searchName = name.toLowerCase().trim();
    for (var item in box.values) {
      if (item.name.toLowerCase().trim() == searchName) {
        return item;
      }
    }

    return null;
  }

  @override
  Future<List<PantryItemModel>> searchItems(String query) async {
    if (query.isEmpty) return getAllItems();
    
    final items = await getAllItems();
    final searchQuery = query.toLowerCase();
    
    return items.where((item) {
      return item.name.toLowerCase().contains(searchQuery) ||
             item.category.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Future<List<PantryItemModel>> getLowStockItems() async {
    final items = await getAllItems();
    return items.where((item) => item.isLowStock).toList();
  }

  @override
  Future<List<PantryItemModel>> getExpiringItems({int days = 7}) async {
    final items = await getAllItems();
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days));
    
    return items.where((item) {
      if (item.expirationDate == null) return false;
      return item.expirationDate!.isBefore(threshold);
    }).toList();
  }
}
