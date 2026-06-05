import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock of [GeolocatorPlatform] so `useCurrentLocation` can be driven without
/// touching real platform channels.
///
/// `MockPlatformInterfaceMixin` bypasses the platform-interface token check,
/// allowing assignment to `GeolocatorPlatform.instance`.
class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

/// Builds a [Position] with all required fields filled in.
Position fakePosition({double lat = 12.9716, double lon = 77.5946}) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

/// Installs a [MockGeolocatorPlatform] as the active instance and stubs it for
/// the happy path (services enabled, permission granted, position returned).
///
/// Pass overrides to exercise the failure modes.
MockGeolocatorPlatform installGeolocatorMock({
  bool serviceEnabled = true,
  LocationPermission checkPermission = LocationPermission.whileInUse,
  LocationPermission requestPermission = LocationPermission.whileInUse,
  Position? position,
}) {
  final mock = MockGeolocatorPlatform();
  GeolocatorPlatform.instance = mock;

  when(mock.isLocationServiceEnabled)
      .thenAnswer((_) async => serviceEnabled);
  when(mock.checkPermission).thenAnswer((_) async => checkPermission);
  when(mock.requestPermission).thenAnswer((_) async => requestPermission);
  when(() => mock.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      )).thenAnswer((_) async => position ?? fakePosition());

  return mock;
}
