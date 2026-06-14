import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jumpin_admin/layouts/master_screen.dart';
import 'package:jumpin_admin/models/city.dart';
import 'package:jumpin_admin/models/search_result.dart';
import 'package:jumpin_admin/providers/city_provider.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  late CityProvider _cityProvider;
  SearchResult<City>? _result;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  static const Color _primary = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    _cityProvider = context.read<CityProvider>();
    _loadCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    try {
      final filter = <String, dynamic>{'PageSize': 1000};
      if (_searchController.text.isNotEmpty) {
        filter['Name'] = _searchController.text;
      }
      final result = await _cityProvider.get(filter: filter);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error loading cities: $e');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleClear() {
    _searchController.clear();
    _loadCities();
  }

  Future<void> _showForm({City? city}) async {
    final isEdit = city != null;
    final nameController = TextEditingController(text: city?.name ?? '');
    final latController =
        TextEditingController(text: city?.latitude?.toString() ?? '');
    final lngController =
        TextEditingController(text: city?.longitude?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit City' : 'Add City'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude *',
                    hintText: 'e.g. 43.8563',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  validator: (v) => _validateCoord(v, -90, 90, 'Latitude'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    hintText: 'e.g. 18.4131',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  validator: (v) => _validateCoord(v, -180, 180, 'Longitude'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final body = {
      'name': nameController.text.trim(),
      'latitude': double.parse(latController.text.trim()),
      'longitude': double.parse(lngController.text.trim()),
    };

    try {
      if (isEdit) {
        await _cityProvider.update(city.id!, body);
        _snack('City updated.');
      } else {
        await _cityProvider.insert(body);
        _snack('City added.');
      }
      await _loadCities();
    } catch (e) {
      _snack('Could not save city: $e');
    }
  }

  String? _validateCoord(String? v, double min, double max, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final d = double.tryParse(v.trim());
    if (d == null) return 'Enter a valid number (e.g. 43.85)';
    if (d < min || d > max) return '$label must be between $min and $max';
    return null;
  }

  Future<void> _deleteCity(City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete City'),
        content: Text('Delete "${city.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _cityProvider.delete(city.id!);
      _snack('City deleted.');
      await _loadCities();
    } catch (e) {
      _snack('Could not delete city. It may be in use.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Cities',
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search cities by name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              onSubmitted: (_) => _loadCities(),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(130, 50),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            onPressed: _loadCities,
            icon: const Icon(Icons.search, size: 20),
            label:
                const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 50),
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[800],
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: _handleClear,
            icon: const Icon(Icons.clear, size: 20),
            label:
                const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 50),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add City',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
    }

    final cities = _result?.result;
    if (cities == null || cities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No cities found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D47A1)),
              headingRowHeight: 56,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columnSpacing: 32,
              horizontalMargin: 24,
              dividerThickness: 1,
              columns: const [
                DataColumn(
                    label: Text('Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13))),
                DataColumn(
                    label: Text('Latitude',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13))),
                DataColumn(
                    label: Text('Longitude',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13))),
              ],
              rows: cities.asMap().entries.map((entry) {
                return _buildRow(entry.value, entry.key.isEven);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(City city, bool isEven) {
    return DataRow(
      color: WidgetStateProperty.all(
        isEven ? Colors.grey.withOpacity(0.02) : Colors.white,
      ),
      cells: [
        DataCell(SizedBox(
          width: 280,
          child: Text(city.name ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        )),
        DataCell(SizedBox(
          width: 160,
          child: Text(city.latitude?.toStringAsFixed(4) ?? '-'),
        )),
        DataCell(SizedBox(
          width: 160,
          child: Text(city.longitude?.toStringAsFixed(4) ?? '-'),
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF0D47A1), size: 20),
                tooltip: 'Edit City',
                onPressed: () => _showForm(city: city),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'Delete City',
                onPressed: () => _deleteCity(city),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
