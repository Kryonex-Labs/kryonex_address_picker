import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kryonex_address_picker_example/main.dart';

void main() {
  testWidgets('App renders pick address button', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Pick an Address'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });
}
