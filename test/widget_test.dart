import 'package:flutter_test/flutter_test.dart';

import 'package:grocery_pantry_app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the app renders successfully
    expect(find.byType(App), findsOneWidget);
  });
}
