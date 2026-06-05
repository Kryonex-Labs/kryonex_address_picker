import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/services/recent_addresses_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageKey = 'kryonex_recent_addresses';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentAddressesService.load', () {
    test('returns [] when nothing stored', () async {
      final service = RecentAddressesService();
      expect(await service.load(), isEmpty);
    });

    test('parses a stored JSON list into addresses', () async {
      final stored = json.encode([buildAddress().toJson()]);
      SharedPreferences.setMockInitialValues({storageKey: stored});

      final loaded = await RecentAddressesService().load();
      expect(loaded, hasLength(1));
      expect(loaded.single.city, 'Bengaluru');
    });

    test('returns [] on malformed stored JSON', () async {
      SharedPreferences.setMockInitialValues({storageKey: 'not json'});
      expect(await RecentAddressesService().load(), isEmpty);
    });
  });

  group('RecentAddressesService.save', () {
    test('persists a saved address so it can be loaded back', () async {
      final service = RecentAddressesService();
      await service.save(buildAddress());

      final loaded = await service.load();
      expect(loaded, hasLength(1));
      expect(loaded.single, buildAddress());
    });

    test('inserts most-recent first', () async {
      final service = RecentAddressesService();
      final a = buildAddress(displayName: 'A');
      final b = buildAddress(displayName: 'B');

      await service.save(a);
      await service.save(b);

      final loaded = await service.load();
      expect(loaded.map((e) => e.displayName), ['B', 'A']);
    });

    test('deduplicates by displayName, moving the dupe to the top', () async {
      final service = RecentAddressesService();
      await service.save(buildAddress(displayName: 'A'));
      await service.save(buildAddress(displayName: 'B'));
      await service.save(buildAddress(displayName: 'A')); // re-save A

      final loaded = await service.load();
      expect(loaded.map((e) => e.displayName), ['A', 'B']);
    });

    test('caps the list at maxAddresses', () async {
      final service = RecentAddressesService(maxAddresses: 2);
      await service.save(buildAddress(displayName: 'A'));
      await service.save(buildAddress(displayName: 'B'));
      await service.save(buildAddress(displayName: 'C'));

      final loaded = await service.load();
      expect(loaded.map((e) => e.displayName), ['C', 'B']);
    });
  });

  group('RecentAddressesService.clear', () {
    test('removes all stored addresses', () async {
      final service = RecentAddressesService();
      await service.save(buildAddress());
      expect(await service.load(), isNotEmpty);

      await service.clear();
      expect(await service.load(), isEmpty);
    });
  });
}
