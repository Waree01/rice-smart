import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/thai_provinces.dart';
import '../providers/location_providers.dart';
import '../providers/weather_providers.dart';

/// Modal bottom sheet for province selection.
///
/// Displays a filterable list of Thai provinces. Users can:
/// - Type to filter by Thai name
/// - Tap to select and save location
/// - Location is persisted to SharedPreferences and updates [weatherQueryProvider]
class LocationPickerDialog extends ConsumerStatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  ConsumerState<LocationPickerDialog> createState() =>
      _LocationPickerDialogState();
}

class _LocationPickerDialogState extends ConsumerState<LocationPickerDialog> {
  late final TextEditingController _filterCtrl;
  List<ThaiProvince> _filteredProvinces = [];

  @override
  void initState() {
    super.initState();
    _filterCtrl = TextEditingController();
    _filteredProvinces = thaiProvinces;
    _filterCtrl.addListener(_updateFilter);
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  void _updateFilter() {
    final query = _filterCtrl.text.toLowerCase();
    setState(() {
      _filteredProvinces = thaiProvinces
          .where((p) => p.nameTh.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _selectProvince(ThaiProvince province) async {
    // Create weather query from province centroid
    final query = WeatherQuery(
      lat: province.latitude,
      lon: province.longitude,
      provinceTh: province.nameTh,
    );

    // Save to repository
    final repo = await ref.read(locationRepositoryProvider.future);
    await repo.saveLocation(query);

    // Update app state
    ref.read(weatherQueryProvider.notifier).state = query;

    // Dismiss dialog
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เลือกจังหวัด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  TextField(
                    controller: _filterCtrl,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาจังหวัด...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Province list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredProvinces.length,
                itemBuilder: (context, index) {
                  final province = _filteredProvinces[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(province.nameTh),
                    subtitle: Text(
                      '${province.nameEn} • ${province.latitude.toStringAsFixed(2)}°, '
                      '${province.longitude.toStringAsFixed(2)}°',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () => _selectProvince(province),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the location picker as a modal bottom sheet.
Future<void> showLocationPickerDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const LocationPickerDialog(),
  );
}
