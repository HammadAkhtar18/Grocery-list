import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:hive/hive.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:grocery_pantry_app/features/pantry/data/models/pantry_item_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_event.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_state.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_bloc.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_event.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_detail_state.dart';
import 'package:grocery_pantry_app/core/constants/app_constants.dart';

void main() {
  setUpAll(() async {
    final dir =
        '${Directory.systemTemp.path}/hive_test_bloc_grocery_${DateTime.now().millisecondsSinceEpoch}';
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
  });

  tearDown(() async {
    final groceryBox = Hive.box<GroceryListModel>(AppConstants.groceryListsBox);
    final pantryBox = Hive.box<PantryItemModel>(AppConstants.pantryItemsBox);
    await groceryBox.clear();
    await pantryBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('GroceryListsBloc', () {
    blocTest<GroceryListsBloc, GroceryListsState>(
      'emits [ListsLoading, ListsLoaded] when LoadLists is added',
      build: () => GroceryListsBloc(),
      act: (bloc) => bloc.add(LoadLists()),
      expect: () => [
        isA<ListsLoading>(),
        isA<ListsLoaded>(),
      ],
    );

    blocTest<GroceryListsBloc, GroceryListsState>(
      'emits ListsLoaded with new list after CreateList',
      build: () => GroceryListsBloc(),
      act: (bloc) => bloc.add(const CreateList('Test List')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<ListsLoading>(),
        isA<ListsLoaded>().having(
          (state) => state.lists.length,
          'list count',
          1,
        ),
      ],
    );

    blocTest<GroceryListsBloc, GroceryListsState>(
      'emits ListsLoaded with empty lists after DeleteList',
      build: () => GroceryListsBloc(),
      seed: () => ListsLoaded([
        GroceryListModel(
          id: 'del-test',
          name: 'Delete Me',
          createdAt: DateTime.now(),
          items: [],
        ),
      ]),
      act: (bloc) => bloc.add(const DeleteList('del-test')),
      expect: () => [
        isA<ListsLoading>(),
        isA<ListsLoaded>().having(
          (state) => state.lists.length,
          'list count',
          0,
        ),
      ],
    );
  });

  group('GroceryDetailBloc', () {
    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'emits [DetailLoading, DetailError] when loading non-existent list',
      build: () => GroceryDetailBloc(),
      act: (bloc) => bloc.add(const LoadDetail('nonexistent-id')),
      expect: () => [
        isA<DetailLoading>(),
        isA<DetailError>().having(
          (state) => state.message,
          'message',
          'The requested item could not be found.',
        ),
      ],
    );

    blocTest<GroceryDetailBloc, GroceryDetailState>(
      'emits DetailLoaded with toggled shopping mode',
      build: () => GroceryDetailBloc(),
      seed: () => DetailLoaded(
        list: GroceryListModel(
          id: 'test',
          name: 'Test',
          createdAt: DateTime.now(),
          items: [],
        ),
      ),
      act: (bloc) => bloc.add(ToggleShoppingMode()),
      expect: () => [
        isA<DetailLoaded>().having(
          (state) => state.shoppingMode,
          'shoppingMode',
          true,
        ),
      ],
    );
  });
}
