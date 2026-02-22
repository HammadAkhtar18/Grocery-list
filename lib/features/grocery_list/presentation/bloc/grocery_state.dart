import 'package:equatable/equatable.dart';
import '../../data/models/grocery_list_model.dart';
import '../../../pantry/data/models/pantry_item_model.dart';

/// States for the GroceryBloc
abstract class GroceryState extends Equatable {
  const GroceryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GroceryInitial extends GroceryState {}

/// Loading state
class GroceryLoading extends GroceryState {}

/// State with loaded grocery lists
class GroceryListsLoaded extends GroceryState {
  final List<GroceryListModel> lists;

  const GroceryListsLoaded(this.lists);

  @override
  List<Object> get props => [lists];
}

/// State with loaded list details
class GroceryListDetailLoaded extends GroceryState {
  final GroceryListModel list;
  final bool shoppingMode;

  const GroceryListDetailLoaded({
    required this.list,
    this.shoppingMode = false,
  });

  @override
  List<Object> get props => [list, shoppingMode];

  GroceryListDetailLoaded copyWith({
    GroceryListModel? list,
    bool? shoppingMode,
  }) {
    return GroceryListDetailLoaded(
      list: list ?? this.list,
      shoppingMode: shoppingMode ?? this.shoppingMode,
    );
  }
}

/// State when duplicate is found in pantry
class DuplicateFound extends GroceryState {
  final PantryItemModel pantryItem;

  const DuplicateFound(this.pantryItem);

  @override
  List<Object> get props => [pantryItem];
}

/// State when no duplicate found
class NoDuplicateFound extends GroceryState {}

/// Error state
class GroceryError extends GroceryState {
  final String message;

  const GroceryError(this.message);

  @override
  List<Object> get props => [message];
}
