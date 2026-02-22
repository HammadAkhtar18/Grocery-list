import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/pantry_item_model.dart';
import '../../data/repositories/pantry_repository_impl.dart';
import '../../domain/repositories/pantry_repository.dart';
import 'pantry_event.dart';
import 'pantry_state.dart';

/// BLoC for managing pantry inventory
class PantryBloc extends Bloc<PantryEvent, PantryState> {
  final PantryRepository _repository;
  final _uuid = const Uuid();

  PantryBloc({PantryRepository? repository})
      : _repository = repository ?? PantryRepositoryImpl(),
        super(PantryInitial()) {
    on<LoadPantry>(_onLoadPantry);
    on<FilterByLocation>(_onFilterByLocation);
    on<SearchPantry>(_onSearchPantry);
    on<AddPantryItem>(_onAddPantryItem);
    on<UpdatePantryItem>(_onUpdatePantryItem);
    on<DeletePantryItem>(_onDeletePantryItem);
  }

  /// Load all pantry items
  Future<void> _onLoadPantry(LoadPantry event, Emitter<PantryState> emit) async {
    emit(PantryLoading());
    try {
      final items = await _repository.getAllItems();
      emit(PantryLoaded(
        items: items,
        filteredItems: items,
      ));
    } catch (e) {
      emit(PantryError('Failed to load pantry: ${e.toString()}'));
    }
  }

  /// Filter items by location
  void _onFilterByLocation(FilterByLocation event, Emitter<PantryState> emit) {
    if (state is PantryLoaded) {
      final currentState = state as PantryLoaded;
      final allItems = currentState.items;

      List<PantryItemModel> filtered;
      if (event.location == null) {
        // "All" tab selected
        filtered = allItems;
      } else {
        filtered = allItems.where((item) => item.location == event.location).toList();
      }

      // Apply search filter if active
      if (currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase();
        filtered = filtered.where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query)).toList();
      }

      emit(currentState.copyWith(
        filteredItems: filtered,
        selectedLocation: event.location,
        clearLocation: event.location == null,
      ));
    }
  }

  /// Search pantry items
  void _onSearchPantry(SearchPantry event, Emitter<PantryState> emit) {
    if (state is PantryLoaded) {
      final currentState = state as PantryLoaded;
      final allItems = currentState.items;

      List<PantryItemModel> filtered = allItems;

      // Apply location filter if active
      if (currentState.selectedLocation != null) {
        filtered = filtered.where((item) => 
            item.location == currentState.selectedLocation).toList();
      }

      // Apply search filter
      if (event.query.isNotEmpty) {
        final query = event.query.toLowerCase();
        filtered = filtered.where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query)).toList();
      }

      emit(currentState.copyWith(
        filteredItems: filtered,
        searchQuery: event.query,
      ));
    }
  }

  /// Add new pantry item
  Future<void> _onAddPantryItem(AddPantryItem event, Emitter<PantryState> emit) async {
    try {
      final itemToAdd = PantryItemModel(
        id: _uuid.v4(),
        name: event.item.name,
        category: event.item.category,
        quantity: event.item.quantity,
        unit: event.item.unit,
        location: event.item.location,
        expirationDate: event.item.expirationDate,
        addedDate: DateTime.now(),
        lowStockThreshold: event.item.lowStockThreshold,
        barcode: event.item.barcode,
      );
      await _repository.addItem(itemToAdd);
      add(LoadPantry());
    } catch (e) {
      emit(PantryError('Failed to add item: ${e.toString()}'));
    }
  }

  /// Update existing pantry item
  Future<void> _onUpdatePantryItem(UpdatePantryItem event, Emitter<PantryState> emit) async {
    try {
      await _repository.updateItem(event.item);
      add(LoadPantry());
    } catch (e) {
      emit(PantryError('Failed to update item: ${e.toString()}'));
    }
  }

  /// Delete pantry item
  Future<void> _onDeletePantryItem(DeletePantryItem event, Emitter<PantryState> emit) async {
    try {
      await _repository.deleteItem(event.itemId);
      add(LoadPantry());
    } catch (e) {
      emit(PantryError('Failed to delete item: ${e.toString()}'));
    }
  }
}
