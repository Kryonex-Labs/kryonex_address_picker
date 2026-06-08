import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:kryonex_address_picker/src/screens/address_detail_screen.dart';

import '../_support/fixtures.dart';

/// Pumps [AddressDetailSheet] inside a [MaterialApp]+[Scaffold] so that
/// [Navigator] and [MediaQuery] are available.
Future<void> pumpSheet(
  WidgetTester tester, {
  List<AddressFieldSpec> fields = const [
    AddressFieldSpec.apt,
    AddressFieldSpec.floor,
    AddressFieldSpec.deliveryNotes,
  ],
}) async {
  final address = buildAddress();
  const config = AddressPickerConfig();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => AddressDetailSheet(
            config: config,
            address: address,
            detailFields: fields,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AddressDetailSheet', () {
    testWidgets('renders the address primary line in the chip', (tester) async {
      await pumpSheet(tester);
      expect(find.text(buildAddress().primaryLine), findsOneWidget);
    });

    testWidgets('renders one text field per spec in detailFields',
        (tester) async {
      await pumpSheet(
        tester,
        fields: [AddressFieldSpec.apt, AddressFieldSpec.floor],
      );

      expect(find.text(AddressFieldSpec.apt.label), findsOneWidget);
      expect(find.text(AddressFieldSpec.floor.label), findsOneWidget);
      expect(find.text(AddressFieldSpec.deliveryNotes.label), findsNothing);
    });

    testWidgets('save button pops with AddressDetails containing entered values',
        (tester) async {
      AddressDetails? saved;
      final address = buildAddress();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  saved = await showModalBottomSheet<AddressDetails>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddressDetailSheet(
                      config: const AddressPickerConfig(),
                      address: address,
                      detailFields: const [AddressFieldSpec.apt],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Enter a value in the apt field.
      await tester.enterText(find.byType(TextField).first, '4B');
      await tester.pumpAndSettle();

      // Tap save.
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(saved?.apt, '4B');
    });

    testWidgets('prefillFrom pre-populates the field with the address attribute',
        (tester) async {
      await pumpSheet(
        tester,
        fields: const [
          AddressFieldSpec(
            key: 'city',
            label: 'City',
            prefillFrom: AddressAttribute.city,
          ),
          AddressFieldSpec.postalCode,
        ],
      );

      final address = buildAddress();
      expect(find.text(address.city!), findsOneWidget);
      expect(find.text(address.postalCode!), findsOneWidget);
    });

    testWidgets('prefilled values are returned on save',
        (tester) async {
      AddressDetails? saved;
      final address = buildAddress();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  saved = await showModalBottomSheet<AddressDetails>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddressDetailSheet(
                      config: const AddressPickerConfig(),
                      address: address,
                      detailFields: const [AddressFieldSpec.postalCode],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(saved?['postalCode'], address.postalCode);
    });

    testWidgets('save with empty field leaves that key absent from values',
        (tester) async {
      AddressDetails? saved;
      final address = buildAddress();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  saved = await showModalBottomSheet<AddressDetails>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddressDetailSheet(
                      config: const AddressPickerConfig(),
                      address: address,
                      detailFields: const [
                        AddressFieldSpec.apt,
                        AddressFieldSpec.floor,
                      ],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Leave fields empty and save.
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      // Both fields empty → AddressDetails.isEmpty
      expect(saved?.isEmpty, isTrue);
    });
  });
}
