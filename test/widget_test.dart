import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:grocery_pantry_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:grocery_pantry_app/core/constants/app_constants.dart';
import 'package:grocery_pantry_app/app.dart';

void main() {
  setUpAll(() async {
    final dir =
        '${Directory.systemTemp.path}/hive_test_widget_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryListModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GroceryItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PantryItemModelAdapter());
    }
    await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
    await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
    await Hive.openBox<dynamic>(AppConstants.appSettingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app renders successfully
    expect(find.byType(App), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
