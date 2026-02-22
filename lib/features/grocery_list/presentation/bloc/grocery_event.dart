import 'package:equatable/equatable.dart';
import '../../data/models/grocery_item_model.dart';

/// Events for the GroceryBloc
abstract class GroceryEvent extends Equatable {
  const GroceryEvent();

  @override
  List<Object?> get props => [];
}

/// Load all grocery lists
class LoadLists extends GroceryEvent {}

/// Create a new grocery list
class CreateList extends GroceryEvent {
  final String name;

  const CreateList(this.name);

  @override
  List<Object> get props => [name];
}

/// Delete a grocery list
class DeleteList extends GroceryEvent {
  final String listId;

  const DeleteList(this.listId);

  @override
  List<Object> get props => [listId];
}

/// Load a specific list's details
class LoadListDetails extends GroceryEvent {
  final String listId;

  const LoadListDetails(this.listId);

  @override
  List<Object> get props => [listId];
}

/// Add an item to a grocery list
class AddItem extends GroceryEvent {
  final String listId;
  final GroceryItemModel item;

  const AddItem(this.listId, this.item);

  @override
  List<Object> get props => [listId, item];
}

/// Update an item in a grocery list
class UpdateItem extends GroceryEvent {
  final String listId;
  final GroceryItemModel item;

  const UpdateItem(this.listId, this.item);

  @override
  List<Object> get props => [listId, item];
}

/// Delete an item from a grocery list
class DeleteItem extends GroceryEvent {
  final String listId;
  final String itemId;

  const DeleteItem(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}

/// Toggle item checked status
class ToggleItem extends GroceryEvent {
  final String listId;
  final String itemId;

  const ToggleItem(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}

/// Toggle shopping mode (hide items in pantry)
class ToggleShoppingMode extends GroceryEvent {}

/// Check for duplicates in pantry
class CheckDuplicate extends GroceryEvent {
  final String name;
  final String? barcode;

  const CheckDuplicate(this.name, {this.barcode});

  @override
  List<Object?> get props => [name, barcode];
}
