import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/main.dart';

void main() {
  testWidgets('Dashboard shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('Bottom navigation has 3 items', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
