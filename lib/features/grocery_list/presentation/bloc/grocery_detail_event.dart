import 'package:equatable/equatable.dart';
import '../../data/models/grocery_item_model.dart';

/// Events for the GroceryDetailBloc (route-scoped, per detail page)
abstract class GroceryDetailEvent extends Equatable {
  const GroceryDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load details of a specific list
class LoadDetail extends GroceryDetailEvent {
  final String listId;

  const LoadDetail(this.listId);

  @override
  List<Object> get props => [listId];
}

/// Add an item to a grocery list
class AddItem extends GroceryDetailEvent {
  final String listId;
  final GroceryItemModel item;

  const AddItem(this.listId, this.item);

  @override
  List<Object> get props => [listId, item];
}

/// Update an item in a grocery list
class UpdateItem extends GroceryDetailEvent {
  final String listId;
  final GroceryItemModel item;

  const UpdateItem(this.listId, this.item);

  @override
  List<Object> get props => [listId, item];
}

/// Delete an item from a grocery list
class DeleteItem extends GroceryDetailEvent {
  final String listId;
  final String itemId;

  const DeleteItem(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}

/// Toggle item checked status
class ToggleItem extends GroceryDetailEvent {
  final String listId;
  final String itemId;

  const ToggleItem(this.listId, this.itemId);

  @override
  List<Object> get props => [listId, itemId];
}

/// Toggle shopping mode (hide items in pantry)
class ToggleShoppingMode extends GroceryDetailEvent {}
