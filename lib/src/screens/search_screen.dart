import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

import '../hooks/use_current_location.dart';
import '../hooks/use_photon_search.dart';
import '../hooks/use_recent_addresses.dart';
import '../models/structured_address.dart';
import '../theme/material_bridge.dart';
import '../theme/picker_theme.dart';
import '../widgets/address_tile.dart';
import '../widgets/recent_address_tile.dart';

/// The primary search screen.
///
/// Shows an auto-focused search bar with autocomplete, recent addresses,
/// a "Use current location" shortcut, and a "Pick on Map" fallback.
class SearchScreen extends HookWidget {
  const SearchScreen({
    super.key,
    required this.config,
    required this.onAddressSelected,
    required this.onPickOnMap,
    required this.onCurrentLocation,
  });

  /// Picker configuration.
  final AddressPickerConfig config;

  /// Called when the user selects an address from search results or recents.
  final ValueChanged<StructuredAddress> onAddressSelected;

  /// Called when the user taps "Pick on Map".
  final VoidCallback onPickOnMap;

  /// Called when the user taps "Use current location" with the resolved coordinates.
  final ValueChanged<StructuredAddress> onCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final queryController = useTextEditingController();
    final query = useState('');

    // Resolve effective country codes + accept-language from config / locale.
    final effectiveCountryCodes = useMemoized(() {
      // Only honour explicitly configured country codes.
      // locale.countryCode is a formatting/language preference, not a physical
      // location — inferring country from it causes hard geographic filtering
      // for users whose device locale doesn't match where they actually are
      // (e.g. en_US locale on an Indian device restricts all results to the US).
      return config.countryCodes;
    }, []);

    final effectiveAcceptLanguage = useMemoized(() {
      if (!config.localeAwareSearch) return null;
      final locale = SchedulerBinding.instance.platformDispatcher.locale;
      return locale.languageCode; // e.g. 'en', 'hi', 'mr'
    }, []);

    final searchState = usePhotonSearch(
      query.value,
      countryCodes: effectiveCountryCodes,
      lang: effectiveAcceptLanguage,
    );
    final recentState = useRecentAddresses(
      maxAddresses: config.maxRecentAddresses,
    );
    final locationState = useCurrentLocation();

    // Listen to text changes.
    useEffect(() {
      void listener() => query.value = queryController.text;
      queryController.addListener(listener);
      return () => queryController.removeListener(listener);
    }, [queryController]);

    final theme = resolveTheme(
      context,
      forUiTheme: config.theme,
      materialTheme: config.materialTheme,
    );

    return FTheme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Address'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FTextField(
                control: FTextFieldControl.managed(controller: queryController),
                hint: config.searchHint ?? 'Search for an address...',
                autofocus: true,
                prefixBuilder: (_, __, ___) =>
                    const Icon(Icons.search, size: 20),
                clearable: (value) => value.text.isNotEmpty,
              ),
            ),

            // Content area
            Expanded(
              child: query.value.isNotEmpty
                  ? _buildSearchResults(searchState)
                  : _buildInitialContent(
                      context,
                      recentState,
                      locationState,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds search results list.
  Widget _buildSearchResults(PhotonSearchState state) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: FAlert(
            title: const Text('Search Error'),
            subtitle: Text(state.error!),
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No results found'),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.results.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final address = state.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AddressTile(
            address: address,
            onTap: () => onAddressSelected(address),
          ),
        );
      },
    );
  }

  /// Builds the initial content: current location, recents, pick on map.
  Widget _buildInitialContent(
    BuildContext context,
    RecentAddressesState recentState,
    CurrentLocationState locationState,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Use current location
        FTile(
          prefix: const Icon(Icons.my_location, size: 20),
          title: const Text('Use current location'),
          suffix: locationState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onPress: locationState.isLoading
              ? null
              : () async {
                  await locationState.fetch();
                  if (locationState.error != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(locationState.error!)),
                      );
                    }
                  }
                },
        ),

        if (locationState.error != null) ...[
          const SizedBox(height: 8),
          FAlert(
            title: const Text('Location Error'),
            subtitle: Text(locationState.error!),
          ),
        ],

        const SizedBox(height: 16),
        const FDivider(),
        const SizedBox(height: 16),

        // Recent addresses
        if (recentState.addresses.isNotEmpty) ...[
          const FLabel(
            layout: FLabelLayout.vertical,
            label: Text('RECENT'),
            child: SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          ...recentState.addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RecentAddressTile(
                address: address,
                onTap: () => onAddressSelected(address),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const FDivider(),
          const SizedBox(height: 16),
        ],

        // Pick on Map fallback
        FButton(
          onPress: onPickOnMap,
          variant: FButtonVariant.outline,
          child: const Text('Pick on Map'),
        ),
      ],
    );
  }
}
