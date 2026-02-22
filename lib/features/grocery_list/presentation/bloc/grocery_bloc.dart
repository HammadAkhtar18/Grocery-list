import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/grocery_list_model.dart';
import '../../data/repositories/grocery_repository_impl.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/domain/repositories/pantry_repository.dart';
import 'grocery_event.dart';
import 'grocery_state.dart';

/// BLoC for managing grocery lists and items
class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  final GroceryRepository _groceryRepository;
  final PantryRepository _pantryRepository;
  final _uuid = const Uuid();

  GroceryBloc({
    GroceryRepository? groceryRepository,
    PantryRepository? pantryRepository,
  })  : _groceryRepository = groceryRepository ?? GroceryRepositoryImpl(),
        _pantryRepository = pantryRepository ?? PantryRepositoryImpl(),
        super(GroceryInitial()) {
    on<LoadLists>(_onLoadLists);
    on<CreateList>(_onCreateList);
    on<DeleteList>(_onDeleteList);
    on<LoadListDetails>(_onLoadListDetails);
    on<AddItem>(_onAddItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
    on<ToggleItem>(_onToggleItem);
    on<ToggleShoppingMode>(_onToggleShoppingMode);
    on<CheckDuplicate>(_onCheckDuplicate);
  }

  /// Load all grocery lists
  Future<void> _onLoadLists(LoadLists event, Emitter<GroceryState> emit) async {
    emit(GroceryLoading());
    try {
      final lists = await _groceryRepository.getAllLists();
      emit(GroceryListsLoaded(lists));
    } catch (e) {
      emit(GroceryError('Failed to load lists: ${e.toString()}'));
    }
  }

  /// Create a new grocery list
  Future<void> _onCreateList(CreateList event, Emitter<GroceryState> emit) async {
    try {
      final newList = GroceryListModel(
        id: _uuid.v4(),
        name: event.name,
        createdAt: DateTime.now(),
        items: [],
      );
      await _groceryRepository.createList(newList);
      add(LoadLists());
    } catch (e) {
      emit(GroceryError('Failed to create list: ${e.toString()}'));
    }
  }

  /// Delete a grocery list
  Future<void> _onDeleteList(DeleteList event, Emitter<GroceryState> emit) async {
    try {
      await _groceryRepository.deleteList(event.listId);
      add(LoadLists());
    } catch (e) {
      emit(GroceryError('Failed to delete list: ${e.toString()}'));
    }
  }

  /// Load details of a specific list and mark items that are in pantry
  Future<void> _onLoadListDetails(LoadListDetails event, Emitter<GroceryState> emit) async {
    emit(GroceryLoading());
    try {
      final list = await _groceryRepository.getListById(event.listId);
      if (list == null) {
        emit(const GroceryError('List not found'));
        return;
      }

      // Check each item against pantry for duplicates
      final updatedItems = await Future.wait(
        list.items.map((item) async {
          final duplicate = await _pantryRepository.checkDuplicate(
            item.name,
            item.barcode,
          );
          return item.copyWith(isInPantry: duplicate != null);
        }),
      );

      final updatedList = list.copyWith(items: updatedItems);
      emit(GroceryListDetailLoaded(list: updatedList));
    } catch (e) {
      emit(GroceryError('Failed to load list details: ${e.toString()}'));
    }
  }

  /// Add item to grocery list
  Future<void> _onAddItem(AddItem event, Emitter<GroceryState> emit) async {
    try {
      // Check if item exists in pantry
      final duplicate = await _pantryRepository.checkDuplicate(
        event.item.name,
        event.item.barcode,
      );
      
      // Mark item as in pantry if duplicate found
      final itemToAdd = event.item.copyWith(
        id: _uuid.v4(),
        isInPantry: duplicate != null,
      );
      
      await _groceryRepository.addItem(event.listId, itemToAdd);
      add(LoadListDetails(event.listId));
    } catch (e) {
      emit(GroceryError('Failed to add item: ${e.toString()}'));
    }
  }

  /// Update item in grocery list
  Future<void> _onUpdateItem(UpdateItem event, Emitter<GroceryState> emit) async {
    try {
      await _groceryRepository.updateItem(event.listId, event.item);
      add(LoadListDetails(event.listId));
    } catch (e) {
      emit(GroceryError('Failed to update item: ${e.toString()}'));
    }
  }

  /// Delete item from grocery list
  Future<void> _onDeleteItem(DeleteItem event, Emitter<GroceryState> emit) async {
    try {
      await _groceryRepository.deleteItem(event.listId, event.itemId);
      add(LoadListDetails(event.listId));
    } catch (e) {
      emit(GroceryError('Failed to delete item: ${e.toString()}'));
    }
  }

  /// Toggle item checked status
  Future<void> _onToggleItem(ToggleItem event, Emitter<GroceryState> emit) async {
    try {
      await _groceryRepository.toggleItem(event.listId, event.itemId);
      add(LoadListDetails(event.listId));
    } catch (e) {
      emit(GroceryError('Failed to toggle item: ${e.toString()}'));
    }
  }

  /// Toggle shopping mode (hide items in pantry)
  void _onToggleShoppingMode(ToggleShoppingMode event, Emitter<GroceryState> emit) {
    if (state is GroceryListDetailLoaded) {
      final currentState = state as GroceryListDetailLoaded;
      emit(currentState.copyWith(shoppingMode: !currentState.shoppingMode));
    }
  }

  /// Check if item exists in pantry (for real-time duplicate detection)
  Future<void> _onCheckDuplicate(CheckDuplicate event, Emitter<GroceryState> emit) async {
    try {
      final duplicate = await _pantryRepository.checkDuplicate(
        event.name,
        event.barcode,
      );
      
      if (duplicate != null) {
        emit(DuplicateFound(duplicate));
      } else {
        emit(NoDuplicateFound());
      }
    } catch (e) {
      // Don't interrupt the add flow, but emit NoDuplicateFound
      debugPrint('Duplicate check failed: $e');
      emit(NoDuplicateFound());
    }
  }
}
