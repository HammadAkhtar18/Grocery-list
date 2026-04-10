import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:grocery_pantry_app/core/exceptions.dart';
import 'package:grocery_pantry_app/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:grocery_pantry_app/features/grocery_list/domain/repositories/grocery_repository.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_event.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_state.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/widgets/add_item_sheet.dart';
import 'package:grocery_pantry_app/features/pantry/domain/repositories/pantry_repository.dart';
import 'package:grocery_pantry_app/features/scanner/presentation/pages/scanner_page.dart';

class MockGroceryListsBloc
    extends MockBloc<GroceryListsEvent, GroceryListsState>
    implements GroceryListsBloc {}

class MockGroceryRepository extends Mock implements GroceryRepository {}

class MockPantryRepository extends Mock implements PantryRepository {}

class FakeGroceryListsEvent extends Fake implements GroceryListsEvent {}

class FakeGroceryListsState extends Fake implements GroceryListsState {}

class _AutoDetectScannerView extends StatefulWidget {
  final void Function(BarcodeCapture capture) onDetect;

  const _AutoDetectScannerView({required this.onDetect});

  @override
  State<_AutoDetectScannerView> createState() => _AutoDetectScannerViewState();
}

class _AutoDetectScannerViewState extends State<_AutoDetectScannerView> {
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasTriggered) return;
      _hasTriggered = true;
      widget.onDetect(
        BarcodeCapture(
          barcodes: const [
            Barcode(rawValue: '1234567890'),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGroceryListsEvent());
    registerFallbackValue(FakeGroceryListsState());
  });

  late MockGroceryListsBloc groceryListsBloc;
  late MockGroceryRepository groceryRepository;
  late MockPantryRepository pantryRepository;

  setUp(() {
    groceryListsBloc = MockGroceryListsBloc();
    groceryRepository = MockGroceryRepository();
    pantryRepository = MockPantryRepository();

    when(() => groceryListsBloc.state).thenReturn(ListsInitial());
    when(() => pantryRepository.checkDuplicate(any(), any()))
        .thenAnswer((_) async => null);
  });

  Future<void> pumpScannerPage(
    WidgetTester tester, {
    required List<GroceryListModel> lists,
  }) async {
    when(() => groceryRepository.getAllLists()).thenAnswer((_) async => lists);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GroceryListsBloc>.value(
          value: groceryListsBloc,
          child: Scaffold(
            body: ScannerPage(
              groceryRepository: groceryRepository,
              pantryRepository: pantryRepository,
              enablePulseAnimation: false,
              scannerViewBuilder: ({
                required MobileScannerController controller,
                required void Function(BarcodeCapture capture) onDetect,
              }) {
                return _AutoDetectScannerView(onDetect: onDetect);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> openListSelectionFlow(WidgetTester tester) async {
    expect(find.text('Barcode Scanned!'), findsOneWidget);
    await tester.tap(find.text('Add to List'));
    await tester.pumpAndSettle();
  }

  Future<void> continueToAddItemSheet(
    WidgetTester tester, {
    String? listName,
  }) async {
    if (listName != null) {
      await tester.tap(find.byKey(const Key('scanner_list_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(listName).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('scanner_continue_button')));
    await tester.pumpAndSettle();
  }

  group('ScannerPage', () {
    testWidgets('renders without crashing when a mock list is provided',
        (WidgetTester tester) async {
      await pumpScannerPage(
        tester,
        lists: [
          GroceryListModel(
            id: 'list-1',
            name: 'Weekend List',
            createdAt: DateTime(2026, 4, 10),
          ),
        ],
      );

      expect(find.byType(ScannerPage), findsOneWidget);

      await openListSelectionFlow(tester);

      expect(find.text('Select List'), findsOneWidget);
      expect(find.text('Weekend List'), findsOneWidget);
    });

    testWidgets(
        'selecting a list from the dropdown updates the selected list ID',
        (WidgetTester tester) async {
      await pumpScannerPage(
        tester,
        lists: [
          GroceryListModel(
            id: 'list-1',
            name: 'Weekend List',
            createdAt: DateTime(2026, 4, 10),
          ),
          GroceryListModel(
            id: 'list-2',
            name: 'Party List',
            createdAt: DateTime(2026, 4, 11),
          ),
        ],
      );

      await openListSelectionFlow(tester);
      await continueToAddItemSheet(tester, listName: 'Party List');

      final addItemSheet =
          tester.widget<AddItemSheet>(find.byType(AddItemSheet));
      expect(addItemSheet.groceryListId, 'list-2');
    });

    testWidgets(
        'a scanned barcode triggers AddItemToList on GroceryListsBloc with the correct listId',
        (WidgetTester tester) async {
      when(() => groceryListsBloc.add(any())).thenAnswer((invocation) {
        final event = invocation.positionalArguments.first as GroceryListsEvent;
        if (event is AddItemToList) {
          event.completer?.complete();
        }
      });

      await pumpScannerPage(
        tester,
        lists: [
          GroceryListModel(
            id: 'list-1',
            name: 'Weekend List',
            createdAt: DateTime(2026, 4, 10),
          ),
        ],
      );

      await openListSelectionFlow(tester);
      await continueToAddItemSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Add to List'));
      await tester.pumpAndSettle();

      verify(
        () => groceryListsBloc.add(
          any(
            that: isA<AddItemToList>()
                .having((event) => event.listId, 'listId', 'list-1')
                .having((event) => event.item.name, 'item name', 'Milk')
                .having(
                  (event) => event.item.barcode,
                  'item barcode',
                  '1234567890',
                ),
          ),
        ),
      ).called(1);
    });

    testWidgets('a StorageException during add shows a SnackBar',
        (WidgetTester tester) async {
      when(() => groceryListsBloc.add(any())).thenAnswer((invocation) {
        final event = invocation.positionalArguments.first as GroceryListsEvent;
        if (event is AddItemToList) {
          event.completer?.completeError(
            const StorageException('Failed to save grocery item.'),
          );
        }
      });

      await pumpScannerPage(
        tester,
        lists: [
          GroceryListModel(
            id: 'list-1',
            name: 'Weekend List',
            createdAt: DateTime(2026, 4, 10),
          ),
        ],
      );

      await openListSelectionFlow(tester);
      await continueToAddItemSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Add to List'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Could not add item'),
        findsOneWidget,
      );
    });
  });
}
