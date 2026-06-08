import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

import 'package:latlong2/latlong.dart';

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
  final ValueChanged<LatLng> onCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final queryController = useTextEditingController();
    final query = useState('');

    // Only honour explicitly configured country codes.
    // locale.countryCode is a formatting/language preference, not a physical
    // location — inferring country from it causes hard geographic filtering
    // for users whose device locale doesn't match where they actually are
    // (e.g. en_US locale on an Indian device restricts all results to the US).
    final effectiveCountryCodes = useMemoized(() {
      return config.countryCodes;
    }, []);

    final effectiveAcceptLanguage = useMemoized(() {
      if (!config.localeAwareSearch) return null;
      final locale = SchedulerBinding.instance.platformDispatcher.locale;
      return locale.languageCode;
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
    final colors = theme.colors;

    return FTheme(
      data: theme,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.foreground),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Search Address',
            style: theme.typography.xl2.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _SearchBar(
                controller: queryController,
                hint: config.searchHint ?? 'Search for an address...',
                colors: colors,
                theme: theme,
              ),
            ),

            // Content area
            Expanded(
              child: query.value.isNotEmpty
                  ? _buildSearchResults(searchState, theme, colors)
                  : _buildInitialContent(
                      context,
                      recentState,
                      locationState,
                      theme,
                      colors,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    PhotonSearchState state,
    FThemeData theme,
    FColors colors,
  ) {
    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: FAlert(
          title: const Text('Search Error'),
          subtitle: Text(state.error!),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No results found',
            style: theme.typography.sm.copyWith(color: colors.mutedForeground),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.results.length,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemBuilder: (context, index) {
        final address = state.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AddressTile(
            address: address,
            onTap: () => onAddressSelected(address),
          ),
        );
      },
    );
  }

  Widget _buildInitialContent(
    BuildContext context,
    RecentAddressesState recentState,
    CurrentLocationState locationState,
    FThemeData theme,
    FColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        // Use current location
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: locationState.isLoading
                ? null
                : () async {
                    await locationState.fetch();
                    if (locationState.error != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locationState.error!)),
                        );
                      }
                    } else if (locationState.location != null) {
                      onCurrentLocation(locationState.location!);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 20, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use current location',
                      style: theme.typography.sm.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (locationState.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
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
          Text(
            'RECENT',
            style: theme.typography.sm.copyWith(
              color: colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...recentState.addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (config.sheetAccentColor ?? colors.primary)
                    .withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FButton(
            onPress: onPickOnMap,
            suffix: const Icon(Icons.map_outlined, size: 18),
            child: const Text('Pick on Map'),
          ),
        ),
      ],
    );
  }
}

/// Fully custom search bar with animated focus border, search icon,
/// and an inline clear button — no FTextField so there's no decoration conflict.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.colors,
    required this.theme,
  });

  final TextEditingController controller;
  final String hint;
  final FColors colors;
  final FThemeData theme;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Color?> _borderColor;
  late final FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _borderColor = ColorTween(
      begin: widget.colors.border.withValues(alpha: 0.5),
      end: widget.colors.primary,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.colors.muted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor.value ??
                  widget.colors.border.withValues(alpha: 0.5),
              width: _focusNode.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(_focusNode.hasFocus),
                  size: 20,
                  color: _focusNode.hasFocus
                      ? widget.colors.primary
                      : widget.colors.mutedForeground,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: widget.theme.typography.sm.copyWith(
                    color: widget.colors.foreground,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: widget.theme.typography.sm.copyWith(
                      color: widget.colors.mutedForeground,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: widget.colors.primary,
                  cursorWidth: 1.5,
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    _focusNode.requestFocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.colors.mutedForeground
                            .withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 11,
                        color: widget.colors.mutedForeground,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 14),
            ],
          ),
        );
      },
    );
  }
}
