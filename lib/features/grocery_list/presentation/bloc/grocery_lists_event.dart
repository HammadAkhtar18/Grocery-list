import 'dart:async';

import 'package:equatable/equatable.dart';
import '../../data/models/grocery_item_model.dart';

/// Events for the GroceryListsBloc (app-scoped, lists-only)
abstract class GroceryListsEvent extends Equatable {
  const GroceryListsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all grocery lists
class LoadLists extends GroceryListsEvent {}

/// Create a new grocery list
class CreateList extends GroceryListsEvent {
  final String name;

  const CreateList(this.name);

  @override
  List<Object> get props => [name];
}

/// Delete a grocery list
class DeleteList extends GroceryListsEvent {
  final String listId;

  const DeleteList(this.listId);

  @override
  List<Object> get props => [listId];
}

/// Add an item to an existing grocery list from app-scoped flows.
class AddItemToList extends GroceryListsEvent {
  final String listId;
  final GroceryItemModel item;
  final Completer<void>? completer;

  const AddItemToList(
    this.listId,
    this.item, {
    this.completer,
  });

  @override
  List<Object> get props => [listId, item];
}
