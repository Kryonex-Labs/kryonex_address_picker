import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

import '../models/address_attribute.dart';
import '../models/address_details.dart';
import '../models/address_field_spec.dart';
import '../models/structured_address.dart';
import '../theme/material_bridge.dart';
import '../theme/picker_theme.dart';

/// Presents the address detail sheet as a frosted-glass modal bottom sheet
/// over the current screen (typically the confirmed map).
///
/// Resolves to the collected [AddressDetails] when the user saves, or `null`
/// if the sheet is dismissed (drag-down, scrim tap, or the edit affordance).
Future<AddressDetails?> showAddressDetailSheet(
  BuildContext context, {
  required AddressPickerConfig config,
  required StructuredAddress address,
  required List<AddressFieldSpec> fields,
}) {
  return showModalBottomSheet<AddressDetails>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    isDismissible: config.sheetDismissible,
    enableDrag: config.sheetEnableDrag,
    builder: (_) => AddressDetailSheet(
      config: config,
      address: address,
      detailFields: fields,
    ),
  );
}

/// Frosted-glass detail sheet — collects configurable [AddressFieldSpec]
/// values over a blurred backdrop of the map.
class AddressDetailSheet extends HookWidget {
  const AddressDetailSheet({
    super.key,
    required this.config,
    required this.address,
    required this.detailFields,
  });

  /// Picker configuration.
  final AddressPickerConfig config;

  /// The confirmed address from the map screen.
  final StructuredAddress address;

  /// Which detail fields to display, in order.
  final List<AddressFieldSpec> detailFields;

  @override
  Widget build(BuildContext context) {
    // One controller per field. Rebuilt only when the field list identity
    // changes, and disposed when this widget leaves the tree.
    final controllers = useMemoized(
      () => {
        for (final field in detailFields)
          field.key: TextEditingController(
            text: field.prefillFrom == null
                ? ''
                : address.readAttribute(field.prefillFrom!) ?? '',
          ),
      },
      [detailFields, address],
    );
    useEffect(
      () => () {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      },
      [controllers],
    );

    final errors = useState<Map<String, String?>>(const {});

    // Clear a field's error as soon as the user edits it (typing or chip tap).
    useEffect(() {
      final listeners = <String, VoidCallback>{};
      controllers.forEach((key, controller) {
        void listener() {
          if (errors.value[key] != null) {
            errors.value = Map<String, String?>.from(errors.value)..remove(key);
          }
        }

        controller.addListener(listener);
        listeners[key] = listener;
      });
      return () {
        controllers.forEach(
          (key, controller) => controller.removeListener(listeners[key]!),
        );
      };
    }, [controllers]);

    final theme = resolveTheme(
      context,
      forUiTheme: config.theme,
      materialTheme: config.materialTheme,
    );
    final colors = theme.colors;
    final radius = Radius.circular(config.sheetCornerRadius);

    void save() {
      final nextErrors = <String, String?>{};
      for (final field in detailFields) {
        final error = field.validate(controllers[field.key]!.text);
        if (error != null) nextErrors[field.key] = error;
      }
      if (nextErrors.isNotEmpty) {
        errors.value = nextErrors;
        return;
      }

      final values = <String, String?>{};
      for (final field in detailFields) {
        final value = controllers[field.key]!.text.trim();
        if (value.isNotEmpty) values[field.key] = value;
      }
      Navigator.of(context).pop(AddressDetails.fromValues(values));
    }

    return FTheme(
      data: theme,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: config.sheetBlurSigma,
              sigmaY: config.sheetBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.vertical(top: radius),
                border: Border(
                  top: BorderSide(color: colors.border.withValues(alpha: 0.6)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 16),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (config.showDragHandle) _DragHandle(colors: colors),
                        _Header(config: config, colors: colors, theme: theme),
                        const SizedBox(height: 16),
                        _AddressChip(
                          address: address,
                          colors: colors,
                          theme: theme,
                          onEdit: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 8),
                        const FDivider(),
                        const SizedBox(height: 4),
                        for (final field in detailFields)
                          _Field(
                            spec: field,
                            controller: controllers[field.key]!,
                            error: errors.value[field.key],
                            colors: colors,
                            onSubmitted: save,
                          ),
                        const SizedBox(height: 8),
                        _SaveButton(
                          label: config.saveButtonLabel,
                          accent: config.sheetAccentColor ?? colors.primary,
                          onPress: save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill drag handle centred at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.colors});

  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.mutedForeground.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Sheet title + optional subtitle.
class _Header extends StatelessWidget {
  const _Header({
    required this.config,
    required this.colors,
    required this.theme,
  });

  final AddressPickerConfig config;
  final FColors colors;
  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.detailSheetTitle,
          style: theme.typography.xl2.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        if (config.detailSheetSubtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            config.detailSheetSubtitle!,
            style: theme.typography.sm.copyWith(color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

/// Read-only hero chip summarising the confirmed address, with an edit
/// affordance that dismisses the sheet (revealing the map behind it).
class _AddressChip extends StatelessWidget {
  const _AddressChip({
    required this.address,
    required this.colors,
    required this.theme,
    required this.onEdit,
  });

  final StructuredAddress address;
  final FColors colors;
  final FThemeData theme;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.primaryLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.sm.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  address.secondaryLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit location',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// A single configurable detail field: label, input, optional quick-fill
/// chips, and an inline error message.
class _Field extends StatelessWidget {
  const _Field({
    required this.spec,
    required this.controller,
    required this.error,
    required this.colors,
    required this.onSubmitted,
  });

  final AddressFieldSpec spec;
  final TextEditingController controller;
  final String? error;
  final FColors colors;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTextField(
            control: FTextFieldControl.managed(controller: controller),
            label: Row(
              children: [
                if (spec.icon != null) ...[
                  Icon(spec.icon, size: 16, color: colors.mutedForeground),
                  const SizedBox(width: 6),
                ],
                Text(spec.label),
              ],
            ),
            hint: spec.hint,
            maxLines: spec.maxLines,
            maxLength: spec.maxLength,
            keyboardType: spec.keyboardType,
            textInputAction: spec.textInputAction,
            error: error != null ? Text(error!) : null,
            onSubmit: (_) => onSubmitted(),
          ),
          if (spec.quickFills != null && spec.quickFills!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in spec.quickFills!)
                    _QuickFillChip(
                      label: value,
                      colors: colors,
                      onTap: () => controller.text = value,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tappable suggestion chip that fills its field with a preset value.
class _QuickFillChip extends StatelessWidget {
  const _QuickFillChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final FColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: colors.muted.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary save button rendered as a glowing pill.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.accent,
    required this.onPress,
  });

  final String label;
  final Color accent;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FButton(
        onPress: onPress,
        suffix: const Icon(Icons.arrow_forward, size: 18),
        child: Text(label),
      ),
    );
  }
}
