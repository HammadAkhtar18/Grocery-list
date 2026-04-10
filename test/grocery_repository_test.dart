import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/repositories/grocery_repository_impl.dart';
import 'package:grocery_pantry_app/core/constants/app_constants.dart';

void main() {
  late GroceryRepositoryImpl repository;

  setUpAll(() async {
    // Initialize Hive for testing in a temp directory
    final dir = '${Directory.systemTemp.path}/hive_test_grocery_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryListModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GroceryItemModelAdapter());
    }
    await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
  });

  setUp(() {
    repository = GroceryRepositoryImpl();
  });

  tearDown(() async {
    final box = Hive.box<GroceryListModel>(AppConstants.groceryListsBox);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('GroceryRepositoryImpl', () {
    test('getAllLists returns empty list initially', () async {
      final lists = await repository.getAllLists();
      expect(lists, isEmpty);
    });

    test('createList adds a new list', () async {
      final list = GroceryListModel(
        id: 'test-id-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        items: [],
      );
      await repository.createList(list);
      final lists = await repository.getAllLists();
      expect(lists.length, 1);
      expect(lists.first.name, 'Test List');
    });

    test('getListById returns null for non-existent list', () async {
      final result = await repository.getListById('non-existent');
      expect(result, isNull);
    });

    test('getListById returns correct list', () async {
      final list = GroceryListModel(
        id: 'test-id-2',
        name: 'Find Me',
        createdAt: DateTime.now(),
        items: [],
      );
      await repository.createList(list);
      final result = await repository.getListById('test-id-2');
      expect(result, isNotNull);
      expect(result!.name, 'Find Me');
    });

    test('deleteList removes the list', () async {
      final list = GroceryListModel(
        id: 'test-id-3',
        name: 'Delete Me',
        createdAt: DateTime.now(),
        items: [],
      );
      await repository.createList(list);
      await repository.deleteList('test-id-3');
      final lists = await repository.getAllLists();
      expect(lists, isEmpty);
    });

    test('addItem adds item to list', () async {
      final list = GroceryListModel(
        id: 'test-id-4',
        name: 'With Items',
        createdAt: DateTime.now(),
        items: [],
      );
      await repository.createList(list);

      final item = GroceryItemModel(
        id: 'item-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 1,
        unit: 'pcs',
      );
      await repository.addItem('test-id-4', item);

      final updated = await repository.getListById('test-id-4');
      expect(updated!.items.length, 1);
      expect(updated.items.first.name, 'Milk');
    });

    test('addItem throws StateError for non-existent list', () async {
      final item = GroceryItemModel(
        id: 'item-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 1,
        unit: 'pcs',
      );
      expect(
        () => repository.addItem('non-existent', item),
        throwsStateError,
      );
    });

    test('toggleItem toggles isChecked', () async {
      final item = GroceryItemModel(
        id: 'item-toggle',
        name: 'Eggs',
        category: 'Dairy',
        quantity: 12,
        unit: 'pcs',
        isChecked: false,
      );
      final list = GroceryListModel(
        id: 'test-id-5',
        name: 'Toggle Test',
        createdAt: DateTime.now(),
        items: [item],
      );
      await repository.createList(list);
      await repository.toggleItem('test-id-5', 'item-toggle');

      final updated = await repository.getListById('test-id-5');
      expect(updated!.items.first.isChecked, true);
    });

    test('deleteItem removes item from list', () async {
      final item = GroceryItemModel(
        id: 'item-del',
        name: 'Rice',
        category: 'Grains',
        quantity: 1,
        unit: 'kg',
      );
      final list = GroceryListModel(
        id: 'test-id-6',
        name: 'Delete Item Test',
        createdAt: DateTime.now(),
        items: [item],
      );
      await repository.createList(list);
      await repository.deleteItem('test-id-6', 'item-del');

      final updated = await repository.getListById('test-id-6');
      expect(updated!.items, isEmpty);
    });
  });
}
