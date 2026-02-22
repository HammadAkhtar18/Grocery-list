import 'package:equatable/equatable.dart';
import '../../data/models/pantry_item_model.dart';

/// States for the PantryBloc
abstract class PantryState extends Equatable {
  const PantryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PantryInitial extends PantryState {}

/// Loading state
class PantryLoading extends PantryState {}

/// State with loaded pantry items
class PantryLoaded extends PantryState {
  final List<PantryItemModel> items;
  final List<PantryItemModel> filteredItems;
  final String? selectedLocation; // null means "All"
  final String searchQuery;

  const PantryLoaded({
    required this.items,
    required this.filteredItems,
    this.selectedLocation,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [items, filteredItems, selectedLocation, searchQuery];

  PantryLoaded copyWith({
    List<PantryItemModel>? items,
    List<PantryItemModel>? filteredItems,
    String? selectedLocation,
    String? searchQuery,
    bool clearLocation = false,
  }) {
    return PantryLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedLocation: clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Error state
class PantryError extends PantryState {
  final String message;

  const PantryError(this.message);

  @override
  List<Object> get props => [message];
}
