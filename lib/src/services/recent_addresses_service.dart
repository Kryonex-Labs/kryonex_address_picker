import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/structured_address.dart';

/// Persists and retrieves recently selected addresses.
///
/// Uses [SharedPreferences] for local storage. Addresses are stored
/// as a JSON array, most-recent-first, capped at [maxAddresses].
class RecentAddressesService {
  RecentAddressesService({
    this.maxAddresses = 5,
    this.storageKey = 'kryonex_recent_addresses',
  });

  /// Maximum number of recent addresses to retain.
  final int maxAddresses;

  /// SharedPreferences key for the address list.
  final String storageKey;

  /// Loads the list of recently selected addresses.
  ///
  /// Returns an empty list if nothing is stored or on parse errors.
  Future<List<StructuredAddress>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> data = json.decode(raw) as List<dynamic>;
      return data
          .map((e) => StructuredAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves an address to the top of the recent list.
  ///
  /// Deduplicates by [StructuredAddress.displayName] — if the address
  /// already exists, it is moved to the top. The list is capped at
  /// [maxAddresses].
  Future<void> save(StructuredAddress address) async {
    final existing = await load();

    // Remove duplicate if present.
    existing.removeWhere((a) => a.displayName == address.displayName);

    // Insert at top.
    existing.insert(0, address);

    // Cap the list.
    final capped = existing.take(maxAddresses).toList();

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(capped.map((a) => a.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  /// Removes all recent addresses from storage.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
