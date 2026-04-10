import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:grocery_pantry_app/core/exceptions.dart';
import 'package:grocery_pantry_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:grocery_pantry_app/features/pantry/data/repositories/pantry_repository_impl.dart';
import 'package:grocery_pantry_app/core/constants/app_constants.dart';

void main() {
  late PantryRepositoryImpl repository;

  setUpAll(() async {
    final dir =
        '${Directory.systemTemp.path}/hive_test_pantry_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PantryItemModelAdapter());
    }
    await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
  });

  setUp(() {
    repository = PantryRepositoryImpl();
  });

  tearDown(() async {
    final box = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('PantryRepositoryImpl', () {
    test('getAllItems returns empty list initially', () async {
      final items = await repository.getAllItems();
      expect(items, isEmpty);
    });

    test('addItem adds a new pantry item', () async {
      final item = PantryItemModel(
        id: 'pantry-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
      );
      await repository.addItem(item);
      final items = await repository.getAllItems();
      expect(items.length, 1);
      expect(items.first.name, 'Milk');
    });

    test('addItem throws when a trimmed case-insensitive duplicate name exists',
        () async {
      final existingItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
      );
      final duplicateItem = PantryItemModel(
        id: 'pantry-2',
        name: '  milk  ',
        category: 'Dairy',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: 'barcode-2',
      );

      await repository.addItem(existingItem);

      await expectLater(
        () => repository.addItem(duplicateItem),
        throwsA(
          isA<DuplicatePantryItemException>().having(
            (exception) => exception.message,
            'message',
            'An item with this name already exists in your pantry.',
          ),
        ),
      );
    });

    test('addItem throws when a duplicate barcode exists', () async {
      final existingItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: 'shared-barcode',
      );
      final duplicateBarcodeItem = PantryItemModel(
        id: 'pantry-2',
        name: 'Butter',
        category: 'Dairy',
        quantity: 1,
        unit: 'pcs',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: 'shared-barcode',
      );

      await repository.addItem(existingItem);

      await expectLater(
        () => repository.addItem(duplicateBarcodeItem),
        throwsA(
          isA<DuplicatePantryItemException>().having(
            (exception) => exception.message,
            'message',
            'An item with this barcode already exists in your pantry.',
          ),
        ),
      );
    });

    test('addItem rejects a different name with the same barcode', () async {
      final existingItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Orange Juice',
        category: 'Beverages',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: 'juice-123',
      );
      final duplicateBarcodeItem = PantryItemModel(
        id: 'pantry-2',
        name: 'Apple Juice',
        category: 'Beverages',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: 'juice-123',
      );

      await repository.addItem(existingItem);

      await expectLater(
        () => repository.addItem(duplicateBarcodeItem),
        throwsA(
          isA<DuplicatePantryItemException>().having(
            (exception) => exception.message,
            'message',
            'An item with this barcode already exists in your pantry.',
          ),
        ),
      );
    });

    test('addItem rejects the same name with a different barcode', () async {
      final existingItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Pasta',
        category: 'Grains',
        quantity: 2,
        unit: 'boxes',
        location: 'Pantry',
        addedDate: DateTime.now(),
        barcode: 'pasta-1',
      );
      final duplicateNameItem = PantryItemModel(
        id: 'pantry-2',
        name: ' pasta ',
        category: 'Grains',
        quantity: 1,
        unit: 'boxes',
        location: 'Pantry',
        addedDate: DateTime.now(),
        barcode: 'pasta-2',
      );

      await repository.addItem(existingItem);

      await expectLater(
        () => repository.addItem(duplicateNameItem),
        throwsA(
          isA<DuplicatePantryItemException>().having(
            (exception) => exception.message,
            'message',
            'An item with this name already exists in your pantry.',
          ),
        ),
      );
    });

    test('addItem succeeds when name and barcode are both unique', () async {
      final firstItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Rice',
        category: 'Grains',
        quantity: 5,
        unit: 'kg',
        location: 'Pantry',
        addedDate: DateTime.now(),
        barcode: 'rice-1',
      );
      final secondItem = PantryItemModel(
        id: 'pantry-2',
        name: 'Beans',
        category: 'Canned Goods',
        quantity: 3,
        unit: 'cans',
        location: 'Pantry',
        addedDate: DateTime.now(),
        barcode: 'beans-1',
      );

      await repository.addItem(firstItem);
      await repository.addItem(secondItem);

      final items = await repository.getAllItems();
      expect(items, hasLength(2));
      expect(items.any((item) => item.name == 'Beans'), isTrue);
    });

    test(
        'updateItem throws when another item already uses the same normalized name',
        () async {
      final existingItem = PantryItemModel(
        id: 'pantry-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
      );
      final itemToUpdate = PantryItemModel(
        id: 'pantry-2',
        name: 'Rice',
        category: 'Grains',
        quantity: 1,
        unit: 'kg',
        location: 'Pantry',
        addedDate: DateTime.now(),
      );

      await repository.addItem(existingItem);
      await repository.addItem(itemToUpdate);

      await expectLater(
        () => repository.updateItem(itemToUpdate.copyWith(name: ' milk ')),
        throwsA(isA<DuplicatePantryItemException>()),
      );
    });

    test('getItemById returns null for non-existent item', () async {
      final result = await repository.getItemById('non-existent');
      expect(result, isNull);
    });

    test('deleteItem removes the item', () async {
      final item = PantryItemModel(
        id: 'pantry-del',
        name: 'Butter',
        category: 'Dairy',
        quantity: 1,
        unit: 'pcs',
        location: 'Fridge',
        addedDate: DateTime.now(),
      );
      await repository.addItem(item);
      await repository.deleteItem('pantry-del');
      final items = await repository.getAllItems();
      expect(items, isEmpty);
    });
  });

  group('checkDuplicate', () {
    test('returns null when pantry is empty', () async {
      final result = await repository.checkDuplicate('Milk', null);
      expect(result, isNull);
    });

    test('finds duplicate by name (case insensitive)', () async {
      final item = PantryItemModel(
        id: 'dup-1',
        name: 'Organic Milk',
        category: 'Dairy',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
      );
      await repository.addItem(item);

      final result = await repository.checkDuplicate('organic milk', null);
      expect(result, isNotNull);
      expect(result!.name, 'Organic Milk');
    });

    test('finds duplicate by barcode', () async {
      final item = PantryItemModel(
        id: 'dup-2',
        name: 'Milk',
        category: 'Dairy',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: '1234567890',
      );
      await repository.addItem(item);

      final result =
          await repository.checkDuplicate('Different Name', '1234567890');
      expect(result, isNotNull);
      expect(result!.barcode, '1234567890');
    });

    test('returns null when no match found', () async {
      final item = PantryItemModel(
        id: 'no-match',
        name: 'Rice',
        category: 'Grains',
        quantity: 1,
        unit: 'kg',
        location: 'Pantry',
        addedDate: DateTime.now(),
      );
      await repository.addItem(item);

      final result = await repository.checkDuplicate('Milk', null);
      expect(result, isNull);
    });

    test('barcode match takes priority', () async {
      final item = PantryItemModel(
        id: 'priority-test',
        name: 'Brand Milk',
        category: 'Dairy',
        quantity: 1,
        unit: 'L',
        location: 'Fridge',
        addedDate: DateTime.now(),
        barcode: '9999',
      );
      await repository.addItem(item);

      // Name doesn't match, but barcode does
      final result =
          await repository.checkDuplicate('Totally Different', '9999');
      expect(result, isNotNull);
      expect(result!.name, 'Brand Milk');
    });
  });
}
