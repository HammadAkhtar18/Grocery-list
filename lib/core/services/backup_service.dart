import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../../features/grocery_list/data/models/grocery_item_model.dart';
import '../../features/grocery_list/data/models/grocery_list_model.dart';
import '../../features/pantry/data/models/pantry_item_model.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  Future<File> createBackupFile() async {
    final groceryBox = Hive.box<GroceryListModel>(AppConstants.groceryListsBox);
    final pantryBox = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);

    final payload = {
      'app': 'Grocery & Pantry',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'groceryLists': groceryBox.values.map(_groceryListToJson).toList(),
      'pantryItems': pantryBox.values.map(_pantryItemToJson).toList(),
    };

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file =
        File('${directory.path}/grocery_pantry_backup_$timestamp.json');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    return file;
  }

  Future<File> exportBackup() async {
    final file = await createBackupFile();

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Grocery & Pantry backup',
      subject: 'Grocery & Pantry backup',
    );

    return file;
  }

  Map<String, Object?> _groceryListToJson(GroceryListModel list) {
    return {
      'id': list.id,
      'name': list.name,
      'createdAt': list.createdAt.toIso8601String(),
      'items': list.items.map(_groceryItemToJson).toList(),
    };
  }

  Map<String, Object?> _groceryItemToJson(GroceryItemModel item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'unit': item.unit,
      'isChecked': item.isChecked,
      'isInPantry': item.isInPantry,
      'barcode': item.barcode,
    };
  }

  Map<String, Object?> _pantryItemToJson(PantryItemModel item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'unit': item.unit,
      'location': item.location,
      'expirationDate': item.expirationDate?.toIso8601String(),
      'addedDate': item.addedDate.toIso8601String(),
      'lowStockThreshold': item.lowStockThreshold,
      'barcode': item.barcode,
    };
  }
}
