import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../exceptions.dart';

const bool kReleaseLogging = bool.fromEnvironment('dart.vm.product');

void appLog(String msg) {
  if (!kReleaseLogging) {
    debugPrint(msg);
  }
}

String userFriendlyErrorMessage(Object error) {
  if (error is DuplicatePantryItemException) {
    return error.message;
  }

  if (_isStorageRelatedError(error)) {
    return 'Something went wrong saving your data. Please try again.';
  }

  if (error is StateError) {
    return 'The requested item could not be found.';
  }

  return 'An unexpected error occurred. Please restart the app if the problem persists.';
}

bool _isStorageRelatedError(Object error) {
  return error is HiveError || error is StorageException;
}
