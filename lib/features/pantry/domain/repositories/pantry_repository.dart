import '../../data/models/pantry_item_model.dart';

/// Repository interface for pantry operations
abstract class PantryRepository {
  /// Get all pantry items
  Future<List<PantryItemModel>> getAllItems();

  /// Get pantry items by location
  Future<List<PantryItemModel>> getItemsByLocation(String location);

  /// Get a single pantry item by ID
  Future<PantryItemModel?> getItemById(String id);

  /// Add a new pantry item
  Future<void> addItem(PantryItemModel item);

  /// Update an existing pantry item
  Future<void> updateItem(PantryItemModel item);

  /// Delete a pantry item
  Future<void> deleteItem(String id);

  /// Check for duplicate item in pantry (by name or barcode)
  /// Returns the matching pantry item if found, null otherwise
  Future<PantryItemModel?> checkDuplicate(String name, String? barcode);

  /// Search pantry items by name
  Future<List<PantryItemModel>> searchItems(String query);

  /// Get items that are low on stock
  Future<List<PantryItemModel>> getLowStockItems();

  /// Get items that are expired or expiring soon
  Future<List<PantryItemModel>> getExpiringItems({int days = 7});
}
