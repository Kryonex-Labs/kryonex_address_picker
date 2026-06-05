import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Relative import so the test runs from the package root:
//   flutter test example/test/widget_test.dart
// The package import would only work when run from inside example/.
// ignore: avoid_relative_lib_imports
import '../lib/main.dart';

void main() {
  testWidgets('App renders pick address button', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Pick an Address'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });
}
