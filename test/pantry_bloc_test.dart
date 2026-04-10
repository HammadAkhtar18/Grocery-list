import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:hive/hive.dart';
import 'package:grocery_pantry_app/core/constants/app_constants.dart';
import 'package:grocery_pantry_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:grocery_pantry_app/features/pantry/presentation/bloc/pantry_bloc.dart';
import 'package:grocery_pantry_app/features/pantry/presentation/bloc/pantry_event.dart';
import 'package:grocery_pantry_app/features/pantry/presentation/bloc/pantry_state.dart';

void main() {
  setUpAll(() async {
    final dir =
        '${Directory.systemTemp.path}/hive_test_bloc_pantry_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PantryItemModelAdapter());
    }
    await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
  });

  tearDown(() async {
    final box = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('PantryBloc', () {
    blocTest<PantryBloc, PantryState>(
      'emits [PantryLoading, PantryLoaded] when LoadPantry is added',
      build: () => PantryBloc(),
      act: (bloc) => bloc.add(LoadPantry()),
      expect: () => [
        isA<PantryLoading>(),
        isA<PantryLoaded>(),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'emits PantryLoaded with new item after AddPantryItem',
      build: () => PantryBloc(),
      act: (bloc) {
        final item = PantryItemModel(
          id: '',
          name: 'Test Milk',
          category: 'Dairy',
          quantity: 1,
          unit: 'L',
          location: 'Fridge',
          addedDate: DateTime.now(),
        );
        bloc.add(AddPantryItem(item));
      },
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<PantryLoading>(),
        isA<PantryLoaded>().having(
          (state) => state.items.length,
          'item count',
          1,
        ),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'emits PantryError when AddPantryItem duplicates an existing pantry item',
      build: () => PantryBloc(),
      act: (bloc) async {
        final box = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);
        await box.put(
          'existing-milk',
          PantryItemModel(
            id: 'existing-milk',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            location: 'Fridge',
            addedDate: DateTime.now(),
          ),
        );

        bloc.add(
          AddPantryItem(
            PantryItemModel(
              id: '',
              name: ' milk ',
              category: 'Dairy',
              quantity: 1,
              unit: 'L',
              location: 'Fridge',
              addedDate: DateTime.now(),
            ),
          ),
        );
      },
      expect: () => [
        const PantryError(
          'An item with this name already exists in your pantry.',
        ),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'emits PantryError when AddPantryItem duplicates an existing barcode',
      build: () => PantryBloc(),
      act: (bloc) async {
        final box = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);
        await box.put(
          'existing-juice',
          PantryItemModel(
            id: 'existing-juice',
            name: 'Orange Juice',
            category: 'Beverages',
            quantity: 1,
            unit: 'L',
            location: 'Fridge',
            addedDate: DateTime.now(),
            barcode: 'barcode-123',
          ),
        );

        bloc.add(
          AddPantryItem(
            PantryItemModel(
              id: '',
              name: 'Apple Juice',
              category: 'Beverages',
              quantity: 1,
              unit: 'L',
              location: 'Fridge',
              addedDate: DateTime.now(),
              barcode: 'barcode-123',
            ),
          ),
        );
      },
      expect: () => [
        const PantryError(
          'An item with this barcode already exists in your pantry.',
        ),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'emits PantryLoaded with empty items after DeletePantryItem',
      build: () => PantryBloc(),
      seed: () {
        final items = [
          PantryItemModel(
            id: 'del-test',
            name: 'Delete Me',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            location: 'Fridge',
            addedDate: DateTime.now(),
          ),
        ];
        return PantryLoaded(
          items: items,
          filteredItems: items,
        );
      },
      act: (bloc) => bloc.add(const DeletePantryItem('del-test')),
      expect: () => [
        isA<PantryLoading>(),
        isA<PantryLoaded>().having(
          (state) => state.items.length,
          'item count',
          0,
        ),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'filters by location when FilterByLocation is added',
      build: () => PantryBloc(),
      seed: () {
        final items = [
          PantryItemModel(
            id: 'fridge-item',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            location: 'Fridge',
            addedDate: DateTime.now(),
          ),
          PantryItemModel(
            id: 'pantry-item',
            name: 'Rice',
            category: 'Grains',
            quantity: 5,
            unit: 'kg',
            location: 'Pantry',
            addedDate: DateTime.now(),
          ),
        ];
        return PantryLoaded(
          items: items,
          filteredItems: items,
        );
      },
      act: (bloc) => bloc.add(const FilterByLocation('Fridge')),
      expect: () => [
        isA<PantryLoaded>().having(
          (state) => state.filteredItems.length,
          'filtered item count',
          1,
        ),
      ],
    );

    blocTest<PantryBloc, PantryState>(
      'searches items when SearchPantry is added',
      build: () => PantryBloc(),
      seed: () {
        final items = [
          PantryItemModel(
            id: 'search-1',
            name: 'Almond Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            location: 'Fridge',
            addedDate: DateTime.now(),
          ),
          PantryItemModel(
            id: 'search-2',
            name: 'White Rice',
            category: 'Grains',
            quantity: 5,
            unit: 'kg',
            location: 'Pantry',
            addedDate: DateTime.now(),
          ),
        ];
        return PantryLoaded(
          items: items,
          filteredItems: items,
        );
      },
      act: (bloc) => bloc.add(const SearchPantry('milk')),
      expect: () => [
        isA<PantryLoaded>().having(
          (state) => state.filteredItems.length,
          'filtered item count',
          1,
        ),
      ],
    );
  });
}
