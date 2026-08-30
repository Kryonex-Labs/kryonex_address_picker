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
  AddressPickerConfig config = const AddressPickerConfig(),
}) async {
  final address = buildAddress();

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
      await tester.enterText(find.byType(EditableText).first, '4B');
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

    testWidgets('blocks save and shows error when required field is empty',
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
                        AddressFieldSpec(
                          key: 'gate',
                          label: 'Gate Code',
                          required: true,
                        ),
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

      // Leave field empty and tap save.
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      // Sheet should still be open (validation blocked save).
      expect(find.text('Gate Code'), findsWidgets);
      // Error message from validate().
      expect(find.text('Gate Code is required'), findsOneWidget);
      // No value was returned.
      expect(saved, isNull);
    });

    testWidgets('validation error clears when user types into the field',
        (tester) async {
      final address = buildAddress();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<AddressDetails>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddressDetailSheet(
                      config: const AddressPickerConfig(),
                      address: address,
                      detailFields: const [
                        AddressFieldSpec(
                          key: 'gate',
                          label: 'Gate Code',
                          required: true,
                        ),
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

      // Trigger validation error.
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();
      expect(find.text('Gate Code is required'), findsOneWidget);

      // Type into the field → error should clear.
      await tester.enterText(find.byType(EditableText).first, 'A');
      await tester.pumpAndSettle();

      expect(find.text('Gate Code is required'), findsNothing);
    });

    testWidgets('quick-fill chips are rendered and fill the field on tap',
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
                        AddressFieldSpec(
                          key: 'building',
                          label: 'Building',
                          quickFills: ['Tower A', 'Tower B'],
                        ),
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

      // Quick-fill chips should be visible.
      expect(find.text('Tower A'), findsOneWidget);
      expect(find.text('Tower B'), findsOneWidget);

      // Tap a chip to fill the field.
      await tester.tap(find.text('Tower A'));
      await tester.pumpAndSettle();

      // Save and verify the chip value was captured.
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(saved?['building'], 'Tower A');
    });

    testWidgets('renders subtitle when config provides detailSheetSubtitle',
        (tester) async {
      await pumpSheet(
        tester,
        config: const AddressPickerConfig(
          detailSheetSubtitle: 'Please review your address',
        ),
      );

      expect(find.text('Please review your address'), findsOneWidget);
    });

    testWidgets('edit button dismisses the sheet with null', (tester) async {
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

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the edit location button (tooltip on _AddressChip).
      await tester.tap(find.byTooltip('Edit location'));
      await tester.pumpAndSettle();

      // Sheet dismissed without saving → null.
      expect(saved, isNull);
    });
  });
}
