import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

import '../models/address_detail_field.dart';
import '../models/address_details.dart';
import '../models/structured_address.dart';
import '../theme/material_bridge.dart';
import '../theme/picker_theme.dart';

/// Address detail screen — collects apt, floor, and delivery notes.
///
/// Shown after map confirmation when [AddressPickerConfig.showDetailScreen]
/// is `true`. Displays a read-only address summary at the top, followed
/// by configurable text fields.
class AddressDetailScreen extends HookWidget {
  const AddressDetailScreen({
    super.key,
    required this.config,
    required this.address,
    required this.onSave,
    required this.detailFields,
  });

  /// Picker configuration.
  final dynamic config;

  /// The confirmed address from the map screen.
  final StructuredAddress address;

  /// Which detail fields to display.
  final List<AddressDetailField> detailFields;

  /// Called when the user saves the address details.
  final ValueChanged<AddressDetails> onSave;

  @override
  Widget build(BuildContext context) {
    final aptController = useTextEditingController();
    final floorController = useTextEditingController();
    final notesController = useTextEditingController();

    final theme = resolveTheme(context);

    return FTheme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Address Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Read-only address summary
              FCard(
                child: FTile(
                  prefix: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(
                    address.primaryLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    address.secondaryLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const FDivider(),
              const SizedBox(height: 24),

              // Detail fields
              ...detailFields.map((field) {
                final controller = switch (field) {
                  AddressDetailField.apt => aptController,
                  AddressDetailField.floor => floorController,
                  AddressDetailField.deliveryNotes => notesController,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FTextField(
                    control: FTextFieldControl.managed(
                      controller: controller,
                    ),
                    label: Text(field.label),
                    hint: field.hint,
                    maxLines:
                        field == AddressDetailField.deliveryNotes ? 3 : 1,
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Save button
              FButton(
                onPress: () {
                  final details = AddressDetails(
                    apt: _nonEmpty(aptController.text),
                    floor: _nonEmpty(floorController.text),
                    deliveryNotes: _nonEmpty(notesController.text),
                  );
                  onSave(details);
                },
                child: const Text('Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns null for empty strings to keep model fields clean.
  String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
