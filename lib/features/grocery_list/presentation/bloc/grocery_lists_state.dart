import 'package:equatable/equatable.dart';
import '../../data/models/grocery_list_model.dart';

/// States for the GroceryListsBloc (app-scoped, lists-only)
abstract class GroceryListsState extends Equatable {
  const GroceryListsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ListsInitial extends GroceryListsState {}

/// Loading state
class ListsLoading extends GroceryListsState {}

/// State with loaded grocery lists
class ListsLoaded extends GroceryListsState {
  final List<GroceryListModel> lists;

  const ListsLoaded(this.lists);

  @override
  List<Object> get props => [lists];
}

/// Error state
class ListsError extends GroceryListsState {
  final String message;

  const ListsError(this.message);

  @override
  List<Object> get props => [message];
}
