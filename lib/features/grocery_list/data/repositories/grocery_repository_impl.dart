import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/exceptions.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../models/grocery_list_model.dart';
import '../models/grocery_item_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Hive-based implementation of the grocery repository
class GroceryRepositoryImpl implements GroceryRepository {
  Box<GroceryListModel>? _box;

  Future<Box<GroceryListModel>> get _groceryBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
    return _box!;
  }

  @override
  Future<List<GroceryListModel>> getAllLists() async {
    return _withStorageHandling('Failed to load grocery lists.', (box) async {
      final lists = box.values.toList();
      // Sort by creation date, newest first
      lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lists;
    });
  }

  @override
  Future<GroceryListModel?> getListById(String id) async {
    return _withStorageHandling(
      'Failed to load grocery list: $id.',
      (box) async {
        try {
          return box.values.firstWhere((list) => list.id == id);
        } on StateError {
          return null;
        }
      },
    );
  }

  @override
  Future<void> createList(GroceryListModel list) async {
    await _withStorageHandling('Failed to create grocery list.', (box) async {
      await box.put(list.id, list);
    });
  }

  @override
  Future<void> updateList(GroceryListModel list) async {
    await _withStorageHandling('Failed to update grocery list.', (box) async {
      await box.put(list.id, list);
    });
  }

  @override
  Future<void> deleteList(String id) async {
    await _withStorageHandling('Failed to delete grocery list.', (box) async {
      await box.delete(id);
    });
  }

  @override
  Future<void> addItem(String listId, GroceryItemModel item) async {
    await _withStorageHandling(
      'Failed to add item to grocery list: $listId.',
      (box) async {
        final list = _requireList(box, listId);
        final updatedItems = List<GroceryItemModel>.from(list.items)..add(item);
        await box.put(list.id, list.copyWith(items: updatedItems));
      },
    );
  }

  @override
  Future<void> updateItem(String listId, GroceryItemModel item) async {
    await _withStorageHandling(
      'Failed to update item in grocery list: $listId.',
      (box) async {
        final list = _requireList(box, listId);
        final updatedItems =
            list.items.map((i) => i.id == item.id ? item : i).toList();
        await box.put(list.id, list.copyWith(items: updatedItems));
      },
    );
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    await _withStorageHandling(
      'Failed to delete item from grocery list: $listId.',
      (box) async {
        final list = _requireList(box, listId);
        final updatedItems = list.items.where((i) => i.id != itemId).toList();
        await box.put(list.id, list.copyWith(items: updatedItems));
      },
    );
  }

  @override
  Future<void> toggleItem(String listId, String itemId) async {
    await _withStorageHandling(
      'Failed to toggle item in grocery list: $listId.',
      (box) async {
        final list = _requireList(box, listId);
        final updatedItems = list.items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(isChecked: !item.isChecked);
          }
          return item;
        }).toList();
        await box.put(list.id, list.copyWith(items: updatedItems));
      },
    );
  }

  GroceryListModel _requireList(Box<GroceryListModel> box, String listId) {
    try {
      return box.values.firstWhere((list) => list.id == listId);
    } on StateError {
      throw StateError('List not found: $listId');
    }
  }

  Future<T> _withStorageHandling<T>(
    String message,
    Future<T> Function(Box<GroceryListModel> box) operation,
  ) async {
    try {
      final box = await _groceryBox;
      return await operation(box);
    } on StorageException {
      rethrow;
    } on HiveError catch (error) {
      throw StorageException(message, cause: error);
    } on Exception catch (error) {
      throw StorageException(message, cause: error);
    }
  }
}
