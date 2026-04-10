import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_event.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/bloc/grocery_lists_state.dart';
import 'package:grocery_pantry_app/features/grocery_list/presentation/widgets/add_item_sheet.dart';
import 'package:grocery_pantry_app/features/pantry/domain/repositories/pantry_repository.dart';

class MockGroceryListsBloc
    extends MockBloc<GroceryListsEvent, GroceryListsState>
    implements GroceryListsBloc {}

class MockPantryRepository extends Mock implements PantryRepository {}

class FakeGroceryListsEvent extends Fake implements GroceryListsEvent {}

class FakeGroceryListsState extends Fake implements GroceryListsState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGroceryListsEvent());
    registerFallbackValue(FakeGroceryListsState());
  });

  late MockGroceryListsBloc groceryListsBloc;
  late MockPantryRepository pantryRepository;

  setUp(() {
    groceryListsBloc = MockGroceryListsBloc();
    pantryRepository = MockPantryRepository();

    when(() => groceryListsBloc.state).thenReturn(ListsInitial());
    when(() => pantryRepository.checkDuplicate(any(), any()))
        .thenAnswer((_) async => null);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GroceryListsBloc>.value(
          value: groceryListsBloc,
          child: Scaffold(
            body: AddItemSheet(
              groceryListId: 'list-1',
              pantryRepository: pantryRepository,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpConstrainedSheet(
    WidgetTester tester, {
    required double height,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GroceryListsBloc>.value(
          value: groceryListsBloc,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                height: height,
                child: AddItemSheet(
                  groceryListId: 'list-1',
                  pantryRepository: pantryRepository,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('AddItemSheet', () {
    testWidgets('renders name field and submit button',
        (WidgetTester tester) async {
      await pumpSheet(tester);

      expect(find.text('Item Name'), findsOneWidget);
      expect(find.text('Add to List'), findsOneWidget);
    });

    testWidgets('renders cleanly in a constrained sheet layout',
        (WidgetTester tester) async {
      await pumpConstrainedSheet(tester, height: 420);

      expect(find.text('Item Name'), findsOneWidget);
      expect(find.text('Add to List'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submitting an empty name does not dispatch an event',
        (WidgetTester tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Add to List'));
      await tester.pump();

      expect(find.text('Please enter an item name'), findsOneWidget);
      verifyNever(() => groceryListsBloc.add(any()));
    });

    testWidgets(
        'submitting a valid name dispatches AddItemToList to GroceryListsBloc',
        (WidgetTester tester) async {
      when(() => groceryListsBloc.add(any())).thenAnswer((invocation) {
        final event = invocation.positionalArguments.first as GroceryListsEvent;
        if (event is AddItemToList) {
          event.completer?.complete();
        }
      });

      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Add to List'));
      await tester.pumpAndSettle();

      verify(
        () => groceryListsBloc.add(
          any(
            that: isA<AddItemToList>()
                .having((event) => event.listId, 'listId', 'list-1')
                .having((event) => event.item.name, 'item name', 'Milk'),
          ),
        ),
      ).called(1);
    });
  });
}
