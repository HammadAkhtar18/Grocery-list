import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/error_handling.dart';
import 'core/services/notification_service.dart';
import 'features/grocery_list/data/models/grocery_item_model.dart';
import 'features/grocery_list/data/models/grocery_list_model.dart';
import 'features/pantry/data/models/pantry_item_model.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Wire this into Firebase Crashlytics or another crash reporting SDK.
    appLog('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // TODO: Wire this into Firebase Crashlytics or another crash reporting SDK.
    appLog('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  // Catch async errors not caught by Flutter
  runZonedGuarded(
    () async {
      runApp(const _HiveBootstrapApp());
    },
    (error, stackTrace) {
      // TODO: Wire this into Firebase Crashlytics or another crash reporting SDK.
      appLog('Zone error: $error\n$stackTrace');
    },
  );
}

class _HiveBootstrapApp extends StatefulWidget {
  const _HiveBootstrapApp();

  @override
  State<_HiveBootstrapApp> createState() => _HiveBootstrapAppState();
}

class _HiveBootstrapAppState extends State<_HiveBootstrapApp> {
  bool _isLoading = true;
  bool _hivePrepared = false;
  bool _isRecoveryDialogVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeHive());
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _HiveErrorApp(message: _errorMessage!);
    }

    if (_isLoading) {
      return const _HiveLoadingApp();
    }

    return const App();
  }

  Future<void> _initializeHive() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final failure = await _tryInitializeHiveWithSafeRetry();
    if (!mounted) return;

    if (failure == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_showRecoveryDialog(failure));
    });
  }

  Future<_HiveStartupFailure?> _tryInitializeHiveWithSafeRetry() async {
    try {
      await _prepareHive();
      await _openHiveBoxes();
      return null;
    } catch (initialError) {
      appLog('Hive initialization attempt failed: $initialError');
      try {
        await _openHiveBoxes();
        return null;
      } catch (retryError) {
        appLog('Hive retry failed: $retryError');
        return _HiveStartupFailure(
          initialError: initialError,
          retryError: retryError,
        );
      }
    }
  }

  Future<void> _prepareHive() async {
    if (_hivePrepared) return;

    await Hive.initFlutter();
    await NotificationService.instance.initialize();
    _registerAdapters();
    _hivePrepared = true;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GroceryItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GroceryListModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PantryItemModelAdapter());
    }
  }

  Future<void> _openHiveBoxes() async {
    await Hive.openBox<GroceryListModel>(AppConstants.groceryListsBox);
    await Hive.openBox<PantryItemModel>(AppConstants.pantryItemsBox);
    await Hive.openBox<dynamic>(AppConstants.appSettingsBox);
  }

  Future<void> _showRecoveryDialog(_HiveStartupFailure failure) async {
    if (_isRecoveryDialogVisible || !mounted) return;

    _isRecoveryDialogVisible = true;
    final action = await showDialog<_HiveRecoveryAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Data Recovery Needed'),
          content: const Text(
            "We couldn't load your saved data. You can try again or reset the "
            'app. Resetting will permanently delete all your grocery and '
            'pantry data.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_HiveRecoveryAction.tryAgain);
              },
              child: const Text('Try Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(_HiveRecoveryAction.resetAppData);
              },
              child: const Text('Reset App Data'),
            ),
          ],
        ),
      ),
    );
    _isRecoveryDialogVisible = false;

    if (!mounted) return;

    if (action == _HiveRecoveryAction.resetAppData) {
      await _resetAppDataAndRetry(failure);
      return;
    }

    unawaited(_initializeHive());
  }

  Future<void> _resetAppDataAndRetry(_HiveStartupFailure failure) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _prepareHive();
      await Hive.close();
      await Hive.deleteBoxFromDisk(AppConstants.groceryListsBox);
      await Hive.deleteBoxFromDisk(AppConstants.pantryItemsBox);
      await _openHiveBoxes();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (resetError) {
      appLog(
        'Hive reset failed.'
        '\nInitial error: ${failure.initialError}'
        '\nRetry error: ${failure.retryError}'
        '\nReset error: $resetError',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = userFriendlyErrorMessage(resetError);
      });
    }
  }
}

enum _HiveRecoveryAction {
  tryAgain,
  resetAppData,
}

class _HiveStartupFailure {
  const _HiveStartupFailure({
    required this.initialError,
    required this.retryError,
  });

  final Object initialError;
  final Object retryError;
}

class _HiveLoadingApp extends StatelessWidget {
  const _HiveLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Loading your saved grocery data...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback app shown when Hive storage is unrecoverable
class _HiveErrorApp extends StatelessWidget {
  const _HiveErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Storage Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
