import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Wraps [child] in the minimal ancestors ForUI widgets require:
/// a [MaterialApp] (for [Directionality]/[MediaQuery]/[Theme]) and an
/// [FTheme]. Use for standalone widget tests of internal widgets.
Widget wrapForTest(Widget child) {
  return MaterialApp(
    home: FTheme(
      data: FTheme.neutral.light.touch,
      child: Scaffold(body: child),
    ),
  );
}

/// A host with a button that, when tapped, calls [onPressed] (typically
/// `showAddressPicker`). Used by the flow integration test so the picker is
/// pushed onto a real [Navigator].
class PickerHost extends StatelessWidget {
  const PickerHost({super.key, required this.onPressed});

  final Future<void> Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}
