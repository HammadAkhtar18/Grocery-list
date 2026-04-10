import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_pantry_app/core/exceptions.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/domain/repositories/grocery_repository.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_bloc.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_event.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_state.dart';
import 'package:grocery_pantry_app/features/pantry/domain/repositories/pantry_repository.dart';

class MockGroceryRepository extends Mock implements GroceryRepository {}

class MockPantryRepository extends Mock implements PantryRepository {}

void main() {
  const storageErrorMessage =
      'Something went wrong saving your data. Please try again.';

  setUpAll(() {
    registerFallbackValue(_testItem());
  });

  late MockGroceryRepository groceryRepository;
  late MockPantryRepository pantryRepository;

  setUp(() {
    groceryRepository = MockGroceryRepository();
    pantryRepository = MockPantryRepository();

    when(() => pantryRepository.checkDuplicate(any(), any()))
        .thenAnswer((_) async => null);
  });

  group('GroceryDetailBloc', () {
    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'LoadDetail emits [DetailLoading, DetailLoaded] with correct list',
      build: () {
        final list = GroceryListModel(
          id: 'list-1',
          name: 'Weekly Groceries',
          createdAt: DateTime(2026, 4, 10),
          items: [_testItem()],
        );

        when(() => groceryRepository.getListById('list-1'))
            .thenAnswer((_) async => list);

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const LoadDetail('list-1')),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>()
            .having((state) => state.list.id, 'id', 'list-1')
            .having((state) => state.list.name, 'name', 'Weekly Groceries')
            .having((state) => state.list.items.length, 'item count', 1),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'AddItem emits updated DetailLoaded with new item',
      build: () {
        var currentList = GroceryListModel(
          id: 'list-1',
          name: 'Weekly Groceries',
          createdAt: DateTime(2026, 4, 10),
          items: [_testItem()],
        );

        when(() => groceryRepository.addItem('list-1', any()))
            .thenAnswer((invocation) async {
          final item = invocation.positionalArguments[1] as GroceryItemModel;
          currentList = currentList.copyWith(
            items: [...currentList.items, item],
          );
        });
        when(() => groceryRepository.getListById('list-1'))
            .thenAnswer((_) async => currentList);

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(
        AddItem(
          'list-1',
          _testItem(id: '', name: 'Milk', barcode: '123456789'),
        ),
      ),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>()
            .having((state) => state.list.items.length, 'item count', 2)
            .having(
              (state) => state.list.items.last.name,
              'added item name',
              'Milk',
            )
            .having(
              (state) => state.list.items.last.barcode,
              'added item barcode',
              '123456789',
            ),
      ],
      verify: (_) {
        verify(
          () => groceryRepository.addItem(
            'list-1',
            any(
              that: isA<GroceryItemModel>()
                  .having((item) => item.name, 'name', 'Milk')
                  .having((item) => item.barcode, 'barcode', '123456789'),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'DeleteItem emits updated DetailLoaded with item removed',
      build: () {
        var currentList = GroceryListModel(
          id: 'list-1',
          name: 'Weekly Groceries',
          createdAt: DateTime(2026, 4, 10),
          items: [
            _testItem(id: 'item-1', name: 'Eggs'),
            _testItem(id: 'item-2', name: 'Milk'),
          ],
        );

        when(() => groceryRepository.deleteItem('list-1', 'item-1'))
            .thenAnswer((_) async {
          currentList = currentList.copyWith(
            items:
                currentList.items.where((item) => item.id != 'item-1').toList(),
          );
        });
        when(() => groceryRepository.getListById('list-1'))
            .thenAnswer((_) async => currentList);

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const DeleteItem('list-1', 'item-1')),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>()
            .having((state) => state.list.items.length, 'item count', 1)
            .having(
              (state) => state.list.items.single.id,
              'remaining id',
              'item-2',
            ),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'ToggleItem emits updated DetailLoaded with toggled item',
      build: () {
        var currentList = GroceryListModel(
          id: 'list-1',
          name: 'Weekly Groceries',
          createdAt: DateTime(2026, 4, 10),
          items: [
            _testItem(id: 'item-1', name: 'Eggs', isChecked: false),
          ],
        );

        when(() => groceryRepository.toggleItem('list-1', 'item-1'))
            .thenAnswer((_) async {
          currentList = currentList.copyWith(
            items: currentList.items
                .map(
                  (item) => item.id == 'item-1'
                      ? item.copyWith(isChecked: !item.isChecked)
                      : item,
                )
                .toList(),
          );
        });
        when(() => groceryRepository.getListById('list-1'))
            .thenAnswer((_) async => currentList);

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const ToggleItem('list-1', 'item-1')),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailLoaded>().having(
          (state) => state.list.items.single.isChecked,
          'checked state',
          true,
        ),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'LoadDetail emits DetailError when the repository throws StorageException',
      build: () {
        when(() => groceryRepository.getListById('list-1')).thenThrow(
          const StorageException('Failed to load grocery list.'),
        );

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const LoadDetail('list-1')),
      expect: () => [
        isA<DetailLoading>(),
        const DetailError(storageErrorMessage),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'AddItem emits DetailError when the repository throws StorageException',
      build: () {
        when(() => groceryRepository.addItem('list-1', any())).thenThrow(
          const StorageException('Failed to add item.'),
        );

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) =>
          bloc.add(AddItem('list-1', _testItem(id: '', name: 'Milk'))),
      expect: () => [
        const DetailError(storageErrorMessage),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'UpdateItem emits DetailError when the repository throws StorageException',
      build: () {
        when(() => groceryRepository.updateItem('list-1', any())).thenThrow(
          const StorageException('Failed to update item.'),
        );

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(UpdateItem('list-1', _testItem(id: 'item-1'))),
      expect: () => [
        const DetailError(storageErrorMessage),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'DeleteItem emits DetailError when the repository throws StorageException',
      build: () {
        when(() => groceryRepository.deleteItem('list-1', 'item-1')).thenThrow(
          const StorageException('Failed to delete item.'),
        );

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const DeleteItem('list-1', 'item-1')),
      expect: () => [
        const DetailError(storageErrorMessage),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'ToggleItem emits DetailError when the repository throws StorageException',
      build: () {
        when(() => groceryRepository.toggleItem('list-1', 'item-1')).thenThrow(
          const StorageException('Failed to toggle item.'),
        );

        return GroceryDetailBloc(
          groceryRepository: groceryRepository,
          pantryRepository: pantryRepository,
        );
      },
      act: (bloc) => bloc.add(const ToggleItem('list-1', 'item-1')),
      expect: () => [
        const DetailError(storageErrorMessage),
      ],
    );
  });
}

GroceryItemModel _testItem({
  String id = 'item-1',
  String name = 'Bread',
  String category = 'Bakery',
  double quantity = 1,
  String unit = 'pcs',
  bool isChecked = false,
  bool isInPantry = false,
  String? barcode,
}) {
  return GroceryItemModel(
    id: id,
    name: name,
    category: category,
    quantity: quantity,
    unit: unit,
    isChecked: isChecked,
    isInPantry: isInPantry,
    barcode: barcode,
  );
}
