import 'package:equatable/equatable.dart';
import '../../data/models/pantry_item_model.dart';

/// Events for the PantryBloc
abstract class PantryEvent extends Equatable {
  const PantryEvent();

  @override
  List<Object?> get props => [];
}

/// Load all pantry items
class LoadPantry extends PantryEvent {}

/// Filter items by location
class FilterByLocation extends PantryEvent {
  final String? location; // null means "All"

  const FilterByLocation(this.location);

  @override
  List<Object?> get props => [location];
}

/// Search pantry items
class SearchPantry extends PantryEvent {
  final String query;

  const SearchPantry(this.query);

  @override
  List<Object> get props => [query];
}

/// Add a new pantry item
class AddPantryItem extends PantryEvent {
  final PantryItemModel item;

  const AddPantryItem(this.item);

  @override
  List<Object> get props => [item];
}

/// Update an existing pantry item
class UpdatePantryItem extends PantryEvent {
  final PantryItemModel item;

  const UpdatePantryItem(this.item);

  @override
  List<Object> get props => [item];
}

/// Delete a pantry item
class DeletePantryItem extends PantryEvent {
  final String itemId;

  const DeletePantryItem(this.itemId);

  @override
  List<Object> get props => [itemId];
}
