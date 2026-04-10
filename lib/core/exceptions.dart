export 'exceptions/storage_exception.dart';

/// Thrown when a pantry write would create a duplicate item.
class DuplicatePantryItemException implements Exception {
  final String message;

  const DuplicatePantryItemException(this.message);

  @override
  String toString() => message;
}
