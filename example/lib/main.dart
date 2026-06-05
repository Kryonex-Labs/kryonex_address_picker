import 'package:flutter/material.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SelectedAddress? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Address Picker Example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _openPicker,
              icon: const Icon(Icons.location_on),
              label: const Text('Pick an Address'),
            ),
            const SizedBox(height: 24),
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
                        _row('Notes', _selectedAddress!.details!.deliveryNotes),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker() async {
    final result = await showAddressPicker(
      context,
      config: const AddressPickerConfig(
        searchHint: 'Where to?',
        maxRecentAddresses: 5,
        showDetailScreen: true,
        countryCodes: ['IN', 'US'],
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
