import '../../data/models/grocery_list_model.dart';
import '../../data/models/grocery_item_model.dart';

/// Repository interface for grocery list operations
abstract class GroceryRepository {
  /// Get all grocery lists
  Future<List<GroceryListModel>> getAllLists();

  /// Get a single grocery list by ID
  Future<GroceryListModel?> getListById(String id);

  /// Create a new grocery list
  Future<void> createList(GroceryListModel list);

  /// Update an existing grocery list
  Future<void> updateList(GroceryListModel list);

  /// Delete a grocery list
  Future<void> deleteList(String id);

  /// Add an item to a grocery list
  Future<void> addItem(String listId, GroceryItemModel item);

  /// Update an item in a grocery list
  Future<void> updateItem(String listId, GroceryItemModel item);

  /// Delete an item from a grocery list
  Future<void> deleteItem(String listId, String itemId);

  /// Toggle item checked status
  Future<void> toggleItem(String listId, String itemId);
}
