import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/exceptions.dart';
import '../../../../core/utils/error_handling.dart';
import '../../data/repositories/grocery_repository_impl.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/domain/repositories/pantry_repository.dart';
import 'grocery_detail_event.dart';
import 'grocery_detail_state.dart';

/// BLoC for managing a single grocery list's detail view (route-scoped).
///
/// Created fresh per navigation to `/list/:id` and auto-closed when the
/// route pops. Handles item CRUD, toggle, and shopping mode.
class GroceryDetailBloc extends Bloc<GroceryDetailEvent, GroceryDetailState> {
  final GroceryRepository _groceryRepository;
  final PantryRepository _pantryRepository;
  final _uuid = const Uuid();

  GroceryDetailBloc({
    GroceryRepository? groceryRepository,
    PantryRepository? pantryRepository,
  })  : _groceryRepository = groceryRepository ?? GroceryRepositoryImpl(),
        _pantryRepository = pantryRepository ?? PantryRepositoryImpl(),
        super(DetailInitial()) {
    on<LoadDetail>(_onLoadDetail);
    on<AddItem>(_onAddItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
    on<ToggleItem>(_onToggleItem);
    on<ToggleShoppingMode>(_onToggleShoppingMode);
  }

  /// Load details of a specific list and mark items that are in pantry
  Future<void> _onLoadDetail(
      LoadDetail event, Emitter<GroceryDetailState> emit) async {
    emit(DetailLoading());
    try {
      final list = await _groceryRepository.getListById(event.listId);
      if (list == null) {
        emit(const DetailError('The requested item could not be found.'));
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
      emit(DetailLoaded(list: updatedList));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onLoadDetail error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onLoadDetail error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }

  /// Add item to grocery list
  Future<void> _onAddItem(
      AddItem event, Emitter<GroceryDetailState> emit) async {
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
      add(LoadDetail(event.listId));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onAddItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onAddItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }

  /// Update item in grocery list
  Future<void> _onUpdateItem(
      UpdateItem event, Emitter<GroceryDetailState> emit) async {
    try {
      await _groceryRepository.updateItem(event.listId, event.item);
      add(LoadDetail(event.listId));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onUpdateItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onUpdateItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }

  /// Delete item from grocery list
  Future<void> _onDeleteItem(
      DeleteItem event, Emitter<GroceryDetailState> emit) async {
    try {
      await _groceryRepository.deleteItem(event.listId, event.itemId);
      add(LoadDetail(event.listId));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onDeleteItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onDeleteItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }

  /// Toggle item checked status
  Future<void> _onToggleItem(
      ToggleItem event, Emitter<GroceryDetailState> emit) async {
    try {
      await _groceryRepository.toggleItem(event.listId, event.itemId);
      add(LoadDetail(event.listId));
    } on StorageException catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onToggleItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onToggleItem error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }

  /// Toggle shopping mode (hide items in pantry)
  void _onToggleShoppingMode(
      ToggleShoppingMode event, Emitter<GroceryDetailState> emit) {
    try {
      if (state is DetailLoaded) {
        final currentState = state as DetailLoaded;
        emit(currentState.copyWith(shoppingMode: !currentState.shoppingMode));
      }
    } catch (e, stackTrace) {
      appLog('GroceryDetailBloc._onToggleShoppingMode error: $e\n$stackTrace');
      emit(DetailError(userFriendlyErrorMessage(e)));
    }
  }
}
