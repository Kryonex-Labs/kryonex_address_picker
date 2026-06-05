import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';

/// A hook that creates and manages a [MapController] lifecycle.
///
/// The controller is created on mount and disposed on unmount,
/// preventing memory leaks when the map screen is popped.
MapController useMapController() {
  final controller = useMemoized(() => MapController(), []);

  // MapController doesn't have a dispose, but we keep this pattern
  // for future compatibility and to bind the lifecycle clearly.
  useEffect(() {
    return () {
      // MapController.dispose() added in flutter_map 7.x+
      controller.dispose();
    };
  }, [controller]);

  return controller;
}
