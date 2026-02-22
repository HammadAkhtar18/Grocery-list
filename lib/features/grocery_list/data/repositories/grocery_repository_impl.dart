import 'package:hive_flutter/hive_flutter.dart';
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
    final box = await _groceryBox;
    final lists = box.values.toList();
    // Sort by creation date, newest first
    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  @override
  Future<GroceryListModel?> getListById(String id) async {
    final box = await _groceryBox;
    try {
      return box.values.firstWhere((list) => list.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createList(GroceryListModel list) async {
    final box = await _groceryBox;
    await box.put(list.id, list);
  }

  @override
  Future<void> updateList(GroceryListModel list) async {
    final box = await _groceryBox;
    await box.put(list.id, list);
  }

  @override
  Future<void> deleteList(String id) async {
    final box = await _groceryBox;
    await box.delete(id);
  }

  @override
  Future<void> addItem(String listId, GroceryItemModel item) async {
    final list = await getListById(listId);
    if (list == null) return;

    final updatedItems = List<GroceryItemModel>.from(list.items)..add(item);
    await updateList(list.copyWith(items: updatedItems));
  }

  @override
  Future<void> updateItem(String listId, GroceryItemModel item) async {
    final list = await getListById(listId);
    if (list == null) return;

    final updatedItems = list.items.map((i) => i.id == item.id ? item : i).toList();
    await updateList(list.copyWith(items: updatedItems));
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    final list = await getListById(listId);
    if (list == null) return;

    final updatedItems = list.items.where((i) => i.id != itemId).toList();
    await updateList(list.copyWith(items: updatedItems));
  }

  @override
  Future<void> toggleItem(String listId, String itemId) async {
    final list = await getListById(listId);
    if (list == null) return;

    final updatedItems = list.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isChecked: !item.isChecked);
      }
      return item;
    }).toList();
    await updateList(list.copyWith(items: updatedItems));
  }
}
