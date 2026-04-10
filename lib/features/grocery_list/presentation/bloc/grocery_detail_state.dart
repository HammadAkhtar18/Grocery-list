import 'package:equatable/equatable.dart';
import '../../data/models/grocery_list_model.dart';

/// States for the GroceryDetailBloc (route-scoped, per detail page)
abstract class GroceryDetailState extends Equatable {
  const GroceryDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DetailInitial extends GroceryDetailState {}

/// Loading state
class DetailLoading extends GroceryDetailState {}

/// State with loaded list details
class DetailLoaded extends GroceryDetailState {
  final GroceryListModel list;
  final bool shoppingMode;

  const DetailLoaded({
    required this.list,
    this.shoppingMode = false,
  });

  @override
  List<Object> get props => [list, shoppingMode];

  DetailLoaded copyWith({
    GroceryListModel? list,
    bool? shoppingMode,
  }) {
    return DetailLoaded(
      list: list ?? this.list,
      shoppingMode: shoppingMode ?? this.shoppingMode,
    );
  }
}

/// Error state
class DetailError extends GroceryDetailState {
  final String message;

  const DetailError(this.message);

  @override
  List<Object> get props => [message];
}
