import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/exceptions.dart';
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
    return _withStorageHandling('Failed to load pantry items.', (box) async {
      final items = box.values.toList();
      // Sort by added date, newest first
      items.sort((a, b) => b.addedDate.compareTo(a.addedDate));
      return items;
    });
  }

  @override
  Future<List<PantryItemModel>> getItemsByLocation(String location) async {
    final items = await getAllItems();
    return items.where((item) => item.location == location).toList();
  }

  @override
  Future<PantryItemModel?> getItemById(String id) async {
    return _withStorageHandling('Failed to load pantry item: $id.',
        (box) async {
      try {
        return box.values.firstWhere((item) => item.id == id);
      } on StateError {
        return null;
      }
    });
  }

  @override
  Future<void> addItem(PantryItemModel item) async {
    await _withStorageHandling('Failed to add pantry item.', (box) async {
      _throwIfDuplicateExists(box, item);
      await box.put(item.id, item);
    });
  }

  @override
  Future<void> updateItem(PantryItemModel item) async {
    await _withStorageHandling('Failed to update pantry item.', (box) async {
      _throwIfDuplicateExists(box, item, excludeItemId: item.id);
      await box.put(item.id, item);
    });
  }

  @override
  Future<void> deleteItem(String id) async {
    await _withStorageHandling('Failed to delete pantry item.', (box) async {
      await box.delete(id);
    });
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
    return _withStorageHandling(
      'Failed to check pantry for duplicate items.',
      (box) async {
        // First try barcode match (exact match)
        if (barcode != null && barcode.isNotEmpty) {
          for (final item in box.values) {
            if (item.barcode != null && item.barcode == barcode) {
              return item;
            }
          }
        }

        // Then try name match (case-insensitive, trimmed)
        final searchName = name.toLowerCase().trim();
        for (final item in box.values) {
          if (item.name.toLowerCase().trim() == searchName) {
            return item;
          }
        }

        return null;
      },
    );
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

  void _throwIfDuplicateExists(
    Box<PantryItemModel> box,
    PantryItemModel item, {
    String? excludeItemId,
  }) {
    final normalizedName = item.name.trim().toLowerCase();
    final normalizedBarcode = item.barcode?.trim();

    for (final existingItem in box.values) {
      if (excludeItemId != null && existingItem.id == excludeItemId) {
        continue;
      }

      if (existingItem.name.trim().toLowerCase() == normalizedName) {
        throw const DuplicatePantryItemException(
          'An item with this name already exists in your pantry.',
        );
      }

      final existingBarcode = existingItem.barcode?.trim();
      if (normalizedBarcode != null &&
          normalizedBarcode.isNotEmpty &&
          existingBarcode != null &&
          existingBarcode.isNotEmpty &&
          existingBarcode == normalizedBarcode) {
        throw const DuplicatePantryItemException(
          'An item with this barcode already exists in your pantry.',
        );
      }
    }
  }

  Future<T> _withStorageHandling<T>(
    String message,
    Future<T> Function(Box<PantryItemModel> box) operation,
  ) async {
    try {
      final box = await _pantryBox;
      return await operation(box);
    } on StorageException {
      rethrow;
    } on DuplicatePantryItemException {
      rethrow;
    } on HiveError catch (error) {
      throw StorageException(message, cause: error);
    } on Exception catch (error) {
      throw StorageException(message, cause: error);
    }
  }
}
