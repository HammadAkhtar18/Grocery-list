import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/exceptions.dart';
import '../../../../core/utils/error_handling.dart';
import '../../data/models/grocery_list_model.dart';
import '../../data/repositories/grocery_repository_impl.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/domain/repositories/pantry_repository.dart';
import 'grocery_lists_event.dart';
import 'grocery_lists_state.dart';

/// BLoC for managing grocery lists (app-scoped).
///
/// Handles list loading and app-wide item mutations for flows that are not
/// inside a route-scoped [GroceryDetailBloc] tree.
class GroceryListsBloc extends Bloc<GroceryListsEvent, GroceryListsState> {
  final GroceryRepository _groceryRepository;
  final PantryRepository _pantryRepository;
  final _uuid = const Uuid();

  GroceryListsBloc({
    GroceryRepository? groceryRepository,
    PantryRepository? pantryRepository,
  })  : _groceryRepository = groceryRepository ?? GroceryRepositoryImpl(),
        _pantryRepository = pantryRepository ?? PantryRepositoryImpl(),
        super(ListsInitial()) {
    on<LoadLists>(_onLoadLists);
    on<CreateList>(_onCreateList);
    on<DeleteList>(_onDeleteList);
    on<AddItemToList>(_onAddItemToList);
  }

  /// Load all grocery lists
  Future<void> _onLoadLists(
      LoadLists event, Emitter<GroceryListsState> emit) async {
    emit(ListsLoading());
    try {
      final lists = await _groceryRepository.getAllLists();
      emit(ListsLoaded(lists));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryListsBloc._onLoadLists error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryListsBloc._onLoadLists error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    }
  }

  /// Create a new grocery list
  Future<void> _onCreateList(
      CreateList event, Emitter<GroceryListsState> emit) async {
    try {
      final newList = GroceryListModel(
        id: _uuid.v4(),
        name: event.name,
        createdAt: DateTime.now(),
        items: [],
      );
      await _groceryRepository.createList(newList);
      add(LoadLists());
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryListsBloc._onCreateList error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryListsBloc._onCreateList error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    }
  }

  /// Delete a grocery list
  Future<void> _onDeleteList(
      DeleteList event, Emitter<GroceryListsState> emit) async {
    try {
      await _groceryRepository.deleteList(event.listId);
      add(LoadLists());
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryListsBloc._onDeleteList error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryListsBloc._onDeleteList error: $e\n$stackTrace');
      emit(ListsError(userFriendlyErrorMessage(e)));
    }
  }

  /// Add an item through the app-scoped bloc so global flows can reuse it.
  Future<void> _onAddItemToList(
      AddItemToList event, Emitter<GroceryListsState> emit) async {
    try {
      final duplicate = await _pantryRepository.checkDuplicate(
        event.item.name,
        event.item.barcode,
      );

      final itemToAdd = event.item.copyWith(
        id: _uuid.v4(),
        isInPantry: duplicate != null,
      );

      await _groceryRepository.addItem(event.listId, itemToAdd);

      if (state is ListsLoaded) {
        final currentState = state as ListsLoaded;
        final updatedLists = currentState.lists
            .map(
              (list) => list.id == event.listId
                  ? list.copyWith(items: [...list.items, itemToAdd])
                  : list,
            )
            .toList();
        emit(ListsLoaded(updatedLists));
      } else {
        final lists = await _groceryRepository.getAllLists();
        emit(ListsLoaded(lists));
      }

      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryListsBloc._onAddItemToList error: $e\n$stackTrace');
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.completeError(e, stackTrace);
      }
      emit(ListsError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryListsBloc._onAddItemToList error: $e\n$stackTrace');
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.completeError(e, stackTrace);
      }
      emit(ListsError(userFriendlyErrorMessage(e)));
    }
  }
}
