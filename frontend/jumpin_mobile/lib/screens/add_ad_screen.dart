import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad.dart';
import '../models/ad_image.dart';
import '../models/city.dart';
import '../providers/auth_provider.dart';
import '../providers/ad_provider.dart';
import '../providers/city_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import 'route_map_picker.dart';
import 'location_picker.dart';

class AddAdScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final Ad? editAd;

  const AddAdScreen({super.key, required this.authProvider, this.editAd});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adProvider = AdProvider();
  final _cityProvider = CityProvider();
  bool _isLoading = false;

  bool get _isEditMode => widget.editAd != null;

  static const Color _primaryColor = Color(0xFF1565C0);

  // Cities
  List<City> _cities = [];
  City? _selectedFromCity;
  City? _selectedToCity;
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _adProvider.setToken(widget.authProvider.token);
    _cityProvider.setToken(widget.authProvider.token);
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityProvider.getCities();
      setState(() {
        _cities = cities;
      });
      if (_isEditMode) {
        _populateEditForm(cities);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _populateEditForm(List<City> cities) {
    final ad = widget.editAd!;
    _titleController.text = ad.title;
    _descriptionController.text = ad.description ?? '';
    _priceController.text = ad.price?.toString() ?? '';
    _dateAvailableController.text = ad.dateAvailable ?? '';
    _timeAvailableController.text = ad.timeAvailable ?? '';
    _uploadedImageUrl = ad.imageUrl;

    // Load existing images
    if (ad.images != null && ad.images!.isNotEmpty) {
      _existingImages = List.from(ad.images!);
    }

    // Determine ad type
    switch (ad.adType.toLowerCase()) {
      case 'car':
      case 'carrental':
        _selectedAdType = 'Car';
        _carBrandController.text = ad.carBrand ?? '';
        _carModelController.text = ad.carModel ?? '';
        _carYearController.text = ad.carYear?.toString() ?? '';
        _carSeatsController.text = ad.carSeats?.toString() ?? '';
        _selectedFuelType = ad.fuelType;
        _selectedCity = cities.cast<City?>().firstWhere(
              (c) => c!.name == ad.location,
              orElse: () => null,
            );
        break;
      case 'apartment':
      case 'apartmentrental':
        _selectedAdType = 'Apartment';
        _apartmentAddressController.text = ad.apartmentAddress ?? '';
        _apartmentRoomsController.text = ad.apartmentRooms?.toString() ?? '';
        _apartmentAreaController.text = ad.apartmentArea?.toString() ?? '';
        _selectedCity = cities.cast<City?>().firstWhere(
              (c) => c!.name == ad.location,
              orElse: () => null,
            );
        break;
      default:
        _selectedAdType = 'Route';
        _routeCoordinatesJson = ad.routeCoordinates;
        _selectedFromCity = cities.cast<City?>().firstWhere(
              (c) => c!.name == ad.locationFrom,
              orElse: () => null,
            );
        _selectedToCity = cities.cast<City?>().firstWhere(
              (c) => c!.name == ad.locationTo,
              orElse: () => null,
            );
    }

    if (ad.latitude != null && ad.longitude != null) {
      _pickedLatitude = ad.latitude;
      _pickedLongitude = ad.longitude;
    }

    setState(() {});
  }

  String _selectedAdType = 'Route';

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateAvailableController = TextEditingController();
  final _timeAvailableController = TextEditingController();

  // Route fields
  String? _routeCoordinatesJson;
  int _routePointCount = 0;

  // Car fields
  final _carBrandController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carYearController = TextEditingController();
  final _carSeatsController = TextEditingController();
  String? _selectedFuelType;

  // Apartment fields
  final _apartmentAddressController = TextEditingController();
  final _apartmentRoomsController = TextEditingController();
  final _apartmentAreaController = TextEditingController();

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'LPG'
  ];

  // Shared location (car/apartment)
  double? _pickedLatitude;
  double? _pickedLongitude;

  // Images
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  List<AdImage> _existingImages = [];
  bool _isUploadingImage = false;
  // Legacy single image for edit mode backwards compatibility
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _dateAvailableController.dispose();
    _timeAvailableController.dispose();
    _carBrandController.dispose();
    _carModelController.dispose();
    _carYearController.dispose();
    _carSeatsController.dispose();
    _apartmentAddressController.dispose();
    _apartmentRoomsController.dispose();
    _apartmentAreaController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _dateAvailableController.clear();
    _timeAvailableController.clear();
    _carBrandController.clear();
    _carModelController.clear();
    _carYearController.clear();
    _carSeatsController.clear();
    _apartmentAddressController.clear();
    _apartmentRoomsController.clear();
    _apartmentAreaController.clear();
    setState(() {
      _selectedAdType = 'Route';
      _selectedFromCity = null;
      _selectedToCity = null;
      _selectedCity = null;
      _routeCoordinatesJson = null;
      _routePointCount = 0;
      _selectedFuelType = null;
      _pickedLatitude = null;
      _pickedLongitude = null;
      _selectedImages.clear();
      _uploadedImageUrls.clear();
      _uploadedImageUrl = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditMode ? 'Update Ad' : 'Create Ad'),
        content: Text(_isEditMode
            ? 'Are you sure you want to save changes?'
            : 'Are you sure you want to publish this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(_isEditMode ? 'Save' : 'Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    final userId = widget.authProvider.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String adType;
    switch (_selectedAdType) {
      case 'Car':
        adType = 'Car';
        break;
      case 'Apartment':
        adType = 'Apartment';
        break;
      default:
        adType = 'Route';
    }

    // Extract coordinates
    double? latitude;
    double? longitude;
    double? latitudeEnd;
    double? longitudeEnd;
    if (_selectedAdType == 'Route' && _routeCoordinatesJson != null) {
      try {
        final coords = jsonDecode(_routeCoordinatesJson!) as List;
        if (coords.isNotEmpty) {
          latitude = (coords.first['lat'] as num).toDouble();
          longitude = (coords.first['lng'] as num).toDouble();
        }
        if (coords.length > 1) {
          latitudeEnd = (coords.last['lat'] as num).toDouble();
          longitudeEnd = (coords.last['lng'] as num).toDouble();
        }
      } catch (_) {}
    } else if (_selectedAdType == 'Route') {
      // Use city coordinates if route map not set
      if (_selectedFromCity != null) {
        latitude = _selectedFromCity!.latitude;
        longitude = _selectedFromCity!.longitude;
      }
      if (_selectedToCity != null) {
        latitudeEnd = _selectedToCity!.latitude;
        longitudeEnd = _selectedToCity!.longitude;
      }
    } else if (_pickedLatitude != null && _pickedLongitude != null) {
      latitude = _pickedLatitude;
      longitude = _pickedLongitude;
    } else if (_selectedCity != null) {
      latitude = _selectedCity!.latitude;
      longitude = _selectedCity!.longitude;
    }

    try {
      if (_isEditMode) {
        await _adProvider.updateAd(
          id: widget.editAd!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          adType: adType,
          price: double.tryParse(_priceController.text) ?? 0,
          dateAvailable: _dateAvailableController.text.isNotEmpty
              ? _dateAvailableController.text
              : null,
          timeAvailable: _timeAvailableController.text.isNotEmpty
              ? _timeAvailableController.text
              : null,
          locationFrom:
              _selectedAdType == 'Route' ? _selectedFromCity?.name : null,
          locationTo: _selectedAdType == 'Route' ? _selectedToCity?.name : null,
          location: (_selectedAdType == 'Car' || _selectedAdType == 'Apartment')
              ? _selectedCity?.name
              : null,
          latitude: latitude,
          longitude: longitude,
          latitudeEnd: latitudeEnd,
          longitudeEnd: longitudeEnd,
          routeCoordinates:
              _selectedAdType == 'Route' ? _routeCoordinatesJson : null,
          carBrand:
              _selectedAdType == 'Car' ? _carBrandController.text.trim() : null,
          carModel:
              _selectedAdType == 'Car' ? _carModelController.text.trim() : null,
          carYear: _selectedAdType == 'Car'
              ? int.tryParse(_carYearController.text)
              : null,
          carSeats: _selectedAdType == 'Car'
              ? int.tryParse(_carSeatsController.text)
              : null,
          fuelType: _selectedAdType == 'Car' ? _selectedFuelType : null,
          apartmentAddress: _selectedAdType == 'Apartment'
              ? _apartmentAddressController.text.trim()
              : null,
          apartmentRooms: _selectedAdType == 'Apartment'
              ? int.tryParse(_apartmentRoomsController.text)
              : null,
          apartmentArea: _selectedAdType == 'Apartment'
              ? double.tryParse(_apartmentAreaController.text)
              : null,
          imageUrl: _uploadedImageUrls.isNotEmpty
              ? _uploadedImageUrls.first
              : (_existingImages.isNotEmpty
                  ? _existingImages.first.imageUrl
                  : _uploadedImageUrl),
        );

        // Create AdImage records for newly uploaded images in edit mode
        if (_uploadedImageUrls.isNotEmpty) {
          final startOrder = _existingImages.length;
          final isMainNeeded = _existingImages.isEmpty;
          for (int i = 0; i < _uploadedImageUrls.length; i++) {
            await _adProvider.createAdImage(
              adId: widget.editAd!.id,
              imageUrl: _uploadedImageUrls[i],
              isMainImage: isMainNeeded && i == 0,
              displayOrder: startOrder + i,
            );
          }
        }
      } else {
        final result = await _adProvider.createAd(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          adType: adType,
          price: double.tryParse(_priceController.text) ?? 0,
          userId: userId,
          dateAvailable: _dateAvailableController.text.isNotEmpty
              ? _dateAvailableController.text
              : null,
          timeAvailable: _timeAvailableController.text.isNotEmpty
              ? _timeAvailableController.text
              : null,
          locationFrom:
              _selectedAdType == 'Route' ? _selectedFromCity?.name : null,
          locationTo: _selectedAdType == 'Route' ? _selectedToCity?.name : null,
          location: (_selectedAdType == 'Car' || _selectedAdType == 'Apartment')
              ? _selectedCity?.name
              : null,
          latitude: latitude,
          longitude: longitude,
          latitudeEnd: latitudeEnd,
          longitudeEnd: longitudeEnd,
          routeCoordinates:
              _selectedAdType == 'Route' ? _routeCoordinatesJson : null,
          carBrand:
              _selectedAdType == 'Car' ? _carBrandController.text.trim() : null,
          carModel:
              _selectedAdType == 'Car' ? _carModelController.text.trim() : null,
          carYear: _selectedAdType == 'Car'
              ? int.tryParse(_carYearController.text)
              : null,
          carSeats: _selectedAdType == 'Car'
              ? int.tryParse(_carSeatsController.text)
              : null,
          fuelType: _selectedAdType == 'Car' ? _selectedFuelType : null,
          apartmentAddress: _selectedAdType == 'Apartment'
              ? _apartmentAddressController.text.trim()
              : null,
          apartmentRooms: _selectedAdType == 'Apartment'
              ? int.tryParse(_apartmentRoomsController.text)
              : null,
          apartmentArea: _selectedAdType == 'Apartment'
              ? double.tryParse(_apartmentAreaController.text)
              : null,
          imageUrl: _uploadedImageUrls.isNotEmpty
              ? _uploadedImageUrls.first
              : _uploadedImageUrl,
        );

        // Create AdImage records for each uploaded image
        if (result != null && _uploadedImageUrls.isNotEmpty) {
          for (int i = 0; i < _uploadedImageUrls.length; i++) {
            await _adProvider.createAdImage(
              adId: result.id,
              imageUrl: _uploadedImageUrls[i],
              isMainImage: i == 0,
              displayOrder: i,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Ad updated successfully!'
                : 'Ad created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!_isEditMode) _resetForm();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showApiError(context, e);
      }
    }
  }

  Future<void> _endAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Ad'),
        content: const Text(
            'Are you sure you want to end this ad? It will no longer be visible to others.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Ad'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _adProvider.endAd(widget.editAd!.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showApiError(context, e);
      }
    }
  }

  Future<void> _deleteAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text(
            'Are you sure you want to delete this ad? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _adProvider.deleteAd(widget.editAd!.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showApiError(context, e);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      _dateAvailableController.text = date.toIso8601String();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      // Check if selected date is today
      final selectedDate = _dateAvailableController.text.isNotEmpty
          ? DateTime.parse(_dateAvailableController.text)
          : null;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final isToday = selectedDate != null
          ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
                  .compareTo(today) ==
              0
          : true;

      // If today is selected, prevent selecting past times
      if (isToday) {
        final selectedTime = time.hour * 60 + time.minute;
        final currentTime = now.hour * 60 + now.minute;
        if (selectedTime < currentTime) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only select future times'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      _timeAvailableController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Ad' : 'Create New Ad'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ad Type Selector
              const Text(
                'Ad Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeButton('Route', Icons.route, Colors.blue[700]!),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                      'Car', Icons.directions_car, Colors.orange[700]!),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                      'Apartment', Icons.apartment, Colors.green[700]!),
                ],
              ),
              const SizedBox(height: 24),

              // Common fields
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (KM) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateAvailableController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        labelText: 'Date Available',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeAvailableController,
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: InputDecoration(
                        labelText: 'Time Available',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Type-specific fields
              _buildTypeSpecificFields(),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Save Changes' : 'Create Ad',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              if (_isEditMode) ...[
                if ((widget.editAd?.status ?? 'Active').toLowerCase() !=
                    'ended')
                  ElevatedButton(
                    onPressed: _isLoading ? null : _endAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'End Ad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _deleteAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete Ad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, Color color) {
    final isSelected = _selectedAdType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAdType = label;
            // Reset location/image when switching types
            _pickedLatitude = null;
            _pickedLongitude = null;
            _selectedImages.clear();
            _uploadedImageUrls.clear();
            _uploadedImageUrl = null;
            _selectedFromCity = null;
            _selectedToCity = null;
            _selectedCity = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedAdType) {
      case 'Route':
        return _buildRouteFields();
      case 'Car':
        return _buildCarFields();
      case 'Apartment':
        return _buildApartmentFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCityDropdown({
    required String label,
    required City? value,
    required ValueChanged<City?> onChanged,
    required IconData icon,
    String? Function(City?)? validator,
  }) {
    return DropdownButtonFormField<City>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      isExpanded: true,
      items: _cities.map((City city) {
        return DropdownMenuItem<City>(
          value: city,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _openLocationPicker(String title) async {
    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          title: title,
          initialLatitude: _pickedLatitude,
          initialLongitude: _pickedLongitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pickedLatitude = result['lat'];
        _pickedLongitude = result['lng'];
      });
    }
  }

  int get _totalImageCount => _existingImages.length + _selectedImages.length;

  Future<void> _pickImage() async {
    if (_totalImageCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum 5 images allowed'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _selectedImages.add(file);
      _isUploadingImage = true;
    });

    final imageUrl = await _adProvider.uploadImage(picked.path);

    setState(() {
      _isUploadingImage = false;
    });

    if (mounted) {
      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrls.add(imageUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image uploaded!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _selectedImages.remove(file);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not upload the image. Ensure it is JPG, PNG or WEBP and under 10MB.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeExistingImage(int index) async {
    final image = _existingImages[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adProvider.deleteAdImage(image.id);
      setState(() {
        _existingImages.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  Widget _buildImagePicker() {
    final hasAnyImages =
        _existingImages.isNotEmpty || _selectedImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (hasAnyImages) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length + _selectedImages.length,
              itemBuilder: (context, index) {
                final isExisting = index < _existingImages.length;
                final isFirst = index == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isExisting
                            ? Image.network(
                                _existingImages[index].imageUrl,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              )
                            : Image.file(
                                _selectedImages[index - _existingImages.length],
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => isExisting
                              ? _removeExistingImage(index)
                              : _removeNewImage(index - _existingImages.length),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      if (isFirst &&
                          (isExisting ? _existingImages[0].isMainImage : true))
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Main',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_totalImageCount < 5)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : _pickImage,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_a_photo),
              label: Text(_isUploadingImage
                  ? 'Uploading...'
                  : 'Add Photo ($_totalImageCount/5)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationPickerButton(String label, Color color) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openLocationPicker(label),
            icon: const Icon(Icons.map),
            label: Text(
              _pickedLatitude == null
                  ? 'Set Location on Map'
                  : 'Change Location on Map',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_pickedLatitude != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location set (${_pickedLatitude!.toStringAsFixed(4)}, ${_pickedLongitude!.toStringAsFixed(4)})',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openRouteMapPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapPicker(
          initialCoordinates: _routeCoordinatesJson,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _routeCoordinatesJson = result;
        try {
          final coords = jsonDecode(result) as List;
          _routePointCount = coords.length;
        } catch (_) {
          _routePointCount = 0;
        }
      });
    }
  }

  Widget _buildRouteFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        _buildCityDropdown(
          label: 'From *',
          value: _selectedFromCity,
          icon: Icons.trip_origin,
          onChanged: (city) {
            setState(() {
              _selectedFromCity = city;
            });
          },
          validator: (value) {
            if (_selectedAdType == 'Route' && value == null) {
              return 'Please select departure city';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildCityDropdown(
          label: 'To *',
          value: _selectedToCity,
          icon: Icons.location_on,
          onChanged: (city) {
            setState(() {
              _selectedToCity = city;
            });
          },
          validator: (value) {
            if (_selectedAdType == 'Route' && value == null) {
              return 'Please select destination city';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openRouteMapPicker,
            icon: const Icon(Icons.map),
            label: Text(
              _routeCoordinatesJson == null
                  ? 'Set Route on Map'
                  : 'Edit Route on Map ($_routePointCount points)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_routeCoordinatesJson != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Route set with $_routePointCount points',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCarFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _carBrandController,
                decoration: InputDecoration(
                  labelText: 'Brand *',
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (_selectedAdType == 'Car' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _carModelController,
                decoration: InputDecoration(
                  labelText: 'Model *',
                  prefixIcon: const Icon(Icons.car_repair),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (_selectedAdType == 'Car' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _carYearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Year',
                  prefixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _carSeatsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Seats',
                  prefixIcon: const Icon(Icons.event_seat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedFuelType,
          decoration: InputDecoration(
            labelText: 'Fuel Type',
            prefixIcon: const Icon(Icons.local_gas_station),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _fuelTypes.map((String fuel) {
            return DropdownMenuItem<String>(
              value: fuel,
              child: Text(fuel),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFuelType = newValue;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildCityDropdown(
          label: 'Location',
          value: _selectedCity,
          icon: Icons.location_on,
          onChanged: (city) {
            setState(() {
              _selectedCity = city;
              if (city != null) {
                _pickedLatitude = city.latitude;
                _pickedLongitude = city.longitude;
              }
            });
          },
        ),
        _buildLocationPickerButton('Car Location', Colors.orange[700]!),
        _buildImagePicker(),
      ],
    );
  }

  Widget _buildApartmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apartment Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _apartmentAddressController,
          decoration: InputDecoration(
            labelText: 'Address *',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (_selectedAdType == 'Apartment' &&
                (value == null || value.trim().isEmpty)) {
              return 'Please enter the apartment address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildCityDropdown(
          label: 'City',
          value: _selectedCity,
          icon: Icons.location_city,
          onChanged: (city) {
            setState(() {
              _selectedCity = city;
              if (city != null) {
                _pickedLatitude = city.latitude;
                _pickedLongitude = city.longitude;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _apartmentRoomsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Rooms',
                  prefixIcon: const Icon(Icons.meeting_room),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _apartmentAreaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Area (m2)',
                  prefixIcon: const Icon(Icons.square_foot),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        _buildLocationPickerButton('Apartment Location', Colors.green[700]!),
        _buildImagePicker(),
      ],
    );
  }
}
