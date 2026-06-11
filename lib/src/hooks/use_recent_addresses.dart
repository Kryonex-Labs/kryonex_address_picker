import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/structured_address.dart';
import '../services/recent_addresses_service.dart';

/// State returned by [useRecentAddresses].
class RecentAddressesState {
  const RecentAddressesState({
    required this.addresses,
    required this.isLoading,
    required this.save,
    required this.clear,
  });

  /// The list of recent addresses, most-recent-first.
  final List<StructuredAddress> addresses;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Saves an address to the top of the recent list.
  final Future<void> Function(StructuredAddress) save;

  /// Clears all recent addresses.
  final Future<void> Function() clear;
}

/// A hook that manages recent address persistence.
///
/// Loads recent addresses on mount and provides [save] and [clear]
/// callbacks. The list auto-refreshes after mutations.
RecentAddressesState useRecentAddresses({int maxAddresses = 5}) {
  final addresses = useState<List<StructuredAddress>>([]);
  final isLoading = useState(true);
  final service = useMemoized(
    () => RecentAddressesService(maxAddresses: maxAddresses),
    [maxAddresses],
  );

  // Load on mount.
  useEffect(() {
    () async {
      try {
        addresses.value = await service.load();
      } catch (e, trace) {
        debugPrint('[AddressPicker] useRecentAddresses.load error: $e\n$trace');
        addresses.value = [];
      } finally {
        isLoading.value = false;
      }
    }();
    return null;
  }, []);

  Future<void> save(StructuredAddress address) async {
    try {
      await service.save(address);
      addresses.value = await service.load();
    } catch (e, trace) {
      debugPrint('[AddressPicker] useRecentAddresses.save error: $e\n$trace');
    }
  }

  Future<void> clear() async {
    try {
      await service.clear();
      addresses.value = [];
    } catch (e, trace) {
      debugPrint('[AddressPicker] useRecentAddresses.clear error: $e\n$trace');
    }
  }

  return RecentAddressesState(
    addresses: addresses.value,
    isLoading: isLoading.value,
    save: save,
    clear: clear,
  );
}
