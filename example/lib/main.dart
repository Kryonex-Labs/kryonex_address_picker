import 'package:flutter/material.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Address Picker Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomePage(themeMode: _themeMode, onThemeModeChanged: _setThemeMode),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SelectedAddress? _selectedAddress;

  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // ─── Demo knobs ───────────────────────────────────────────────────────────

  /// Which dark-mode strategy to use for map tiles.
  MapDarkMode _mapDarkMode = MapDarkMode.auto;

  /// Whether to replace the built-in pin with a custom widget.
  bool _useCustomPin = false;

  /// Whether to apply a custom confirm-button style.
  bool _useCustomButtonStyle = false;

  /// Whether to show OSM attribution (null = suppress, non-null = show).
  bool _showAttribution = true;

  /// Whether to use a custom attribution label.
  bool _useCustomAttribution = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Picker Example'),
        actions: [
          // Quick toggle between light / dark / system so testers can
          // exercise mapDarkMode: auto without editing code.
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Theme mode',
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('System')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Config knobs ──────────────────────────────────────────────
              _SectionHeader('Geocoding'),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Google Maps API Key',
                  hintText: 'Leave empty to use Photon (free)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_apiKeyController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Google Geocoding → Photon fallback',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionHeader('Map dark mode'),
              SegmentedButton<MapDarkMode>(
                segments: const [
                  ButtonSegment(
                    value: MapDarkMode.auto,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: MapDarkMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: MapDarkMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {_mapDarkMode},
                onSelectionChanged: (s) =>
                    setState(() => _mapDarkMode = s.first),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Pin & button'),
              SwitchListTile(
                title: const Text('Custom pin builder'),
                subtitle: const Text(
                  'Replaces the default MapPin with a coloured star icon',
                ),
                value: _useCustomPin,
                onChanged: (v) => setState(() => _useCustomPin = v),
              ),
              SwitchListTile(
                title: const Text('Custom confirmButtonStyle'),
                subtitle: const Text(
                  'Overrides the Confirm Address button with a teal style',
                ),
                value: _useCustomButtonStyle,
                onChanged: (v) => setState(() => _useCustomButtonStyle = v),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Attribution'),
              SwitchListTile(
                title: const Text('Show attribution'),
                subtitle: const Text(
                  'Disable to suppress the OSM attribution widget '
                  '(not recommended — violates OSM tile policy)',
                ),
                value: _showAttribution,
                onChanged: (v) => setState(() => _showAttribution = v),
              ),
              if (_showAttribution)
                SwitchListTile(
                  title: const Text('Custom attribution label'),
                  subtitle: const Text(
                    'Uses a custom text and left-side alignment instead of '
                    'the default OSM text',
                  ),
                  value: _useCustomAttribution,
                  onChanged: (v) => setState(() => _useCustomAttribution = v),
                ),

              const SizedBox(height: 24),

              // ── Launch button ────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _openPicker,
                icon: const Icon(Icons.location_on),
                label: const Text('Pick an Address'),
              ),

              const SizedBox(height: 24),

              // ── Result card ──────────────────────────────────────────────
              if (_selectedAddress != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Address',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _row('Display', _selectedAddress!.address.displayName),
                        _row('Street', _selectedAddress!.address.street),
                        _row('House #', _selectedAddress!.address.houseNumber),
                        _row('City', _selectedAddress!.address.city),
                        _row('State', _selectedAddress!.address.state),
                        _row('Postal', _selectedAddress!.address.postalCode),
                        _row('Country', _selectedAddress!.address.country),
                        _row('Code', _selectedAddress!.address.countryCode),
                        _row(
                          'Lat',
                          '${_selectedAddress!.address.latLng.latitude}',
                        ),
                        _row(
                          'Lng',
                          '${_selectedAddress!.address.latLng.longitude}',
                        ),
                        if (_selectedAddress!.details != null) ...[
                          const Divider(),
                          _row('Apt', _selectedAddress!.details!.apt),
                          _row('Floor', _selectedAddress!.details!.floor),
                          _row('Gate', _selectedAddress!.details!['gate']),
                          _row(
                            'Notes',
                            _selectedAddress!.details!.deliveryNotes,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker() async {
    // Resolve the effective attribution based on the demo knobs.
    final AddressPickerAttribution? attribution = !_showAttribution
        ? null
        : _useCustomAttribution
        ? const AddressPickerAttribution(
            text: 'Tiles by Example Corp',
            alignment: MapAttributionAlignment.bottomLeft,
          )
        : AddressPickerAttribution.osm;

    final result = await showAddressPicker(
      context,
      config: AddressPickerConfig(
        googleMapsApiKey: _apiKeyController.text.isNotEmpty
            ? _apiKeyController.text
            : null,
        searchHint: 'Where to?',
        maxRecentAddresses: 5,
        showDetailScreen: true,
        countryCodes: const ['IN', 'US'],
        detailSheetSubtitle: 'Help your courier find the door',
        // ── New theming fields ────────────────────────────────────────────
        mapDarkMode: _mapDarkMode,
        pinBuilder: _useCustomPin
            ? (context) => Icon(
                Icons.star,
                size: 40,
                color: Theme.of(context).colorScheme.tertiary,
              )
            : null,
        confirmButtonStyle: _useCustomButtonStyle
            ? FilledButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              )
            : null,
        attributionStyle: attribution,
        // ── Other existing fields ─────────────────────────────────────────
        detailFields: const [
          AddressFieldSpec.apt,
          AddressFieldSpec.floor,
          AddressFieldSpec(
            key: 'gate',
            label: 'Gate code',
            hint: 'e.g. 1234',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            quickFills: ['1234', '0000', 'Call me'],
          ),
          // Pre-filled from the confirmed address. Users can still edit.
          AddressFieldSpec(
            key: 'street',
            label: 'Street',
            hint: 'e.g. Main Street',
            icon: Icons.signpost_outlined,
            prefillFrom: AddressAttribute.street,
          ),
          AddressFieldSpec(
            key: 'city',
            label: 'City',
            icon: Icons.location_city_outlined,
            prefillFrom: AddressAttribute.city,
          ),
          AddressFieldSpec.postalCode,
          AddressFieldSpec.deliveryNotes,
        ],
      ),
    );

    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  Widget _row(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
