import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/grocery_list/data/models/grocery_item_model.dart';
import 'features/grocery_list/data/models/grocery_list_model.dart';
import 'features/pantry/data/models/pantry_item_model.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  // Catch async errors not caught by Flutter
  runZonedGuarded(
    () async {
      try {
        // Initialize Hive
        await Hive.initFlutter();

        // Register Hive type adapters
        Hive.registerAdapter(GroceryItemModelAdapter());
        Hive.registerAdapter(GroceryListModelAdapter());
        Hive.registerAdapter(PantryItemModelAdapter());

        // Open Hive boxes
        await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
        await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
      } catch (e) {
        debugPrint('Hive initialization error: $e');
        // If Hive fails, try to delete corrupted boxes and reinitialize
        try {
          await Hive.deleteBoxFromDisk(AppConstants.groceryListsBox);
          await Hive.deleteBoxFromDisk(AppConstants.pantryItemsBox);
          await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
          await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
        } catch (_) {
          debugPrint('Critical: Could not recover Hive storage');
        }
      }

      runApp(const App());
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}
