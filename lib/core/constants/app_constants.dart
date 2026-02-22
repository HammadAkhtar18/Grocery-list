/// Application constants for categories, units, and storage locations
class AppConstants {
  AppConstants._();

  /// Item categories for groceries and pantry items
  static const List<String> categories = [
    'Dairy',
    'Produce',
    'Meat & Seafood',
    'Bakery',
    'Frozen',
    'Canned Goods',
    'Beverages',
    'Snacks',
    'Condiments',
    'Grains & Pasta',
    'Household',
    'Personal Care',
    'Other',
  ];

  /// Units for quantity measurement
  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'lb',
    'oz',
    'L',
    'ml',
    'bottles',
    'cans',
    'boxes',
    'bags',
    'packs',
  ];

  /// Storage locations for pantry items
  static const List<String> locations = [
    'Fridge',
    'Freezer',
    'Pantry',
    'Other',
  ];

  /// Hive box names
  static const String groceryListsBox = 'grocery_lists';
  static const String pantryItemsBox = 'pantry_items';

  /// Hive type IDs
  static const int groceryListTypeId = 0;
  static const int groceryItemTypeId = 1;
  static const int pantryItemTypeId = 2;
}
