import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

const String _googleApiKey = Config.googleMapsApiKey;

class RouteMapPicker extends StatefulWidget {
  final String? initialCoordinates;

  const RouteMapPicker({super.key, this.initialCoordinates});

  @override
  State<RouteMapPicker> createState() => _RouteMapPickerState();
}

class _RouteMapPickerState extends State<RouteMapPicker> {
  GoogleMapController? _mapController;
  final List<LatLng> _waypoints = [];
  List<LatLng> _roadPolylinePoints = [];
  bool _isLoadingRoute = false;

  static const Color _primaryColor = Color(0xFF1565C0);
  static const LatLng _bosniaCenter = LatLng(43.85, 17.67);

  @override
  void initState() {
    super.initState();
    _loadInitialCoordinates();
  }

  void _loadInitialCoordinates() {
    if (widget.initialCoordinates != null &&
        widget.initialCoordinates!.isNotEmpty) {
      try {
        final List<dynamic> coords = jsonDecode(widget.initialCoordinates!);
        for (var coord in coords) {
          _waypoints.add(LatLng(
            (coord['lat'] as num).toDouble(),
            (coord['lng'] as num).toDouble(),
          ));
        }
        if (_waypoints.length >= 2) {
          _fetchDirections();
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchDirections() async {
    if (_waypoints.length < 2) {
      setState(() {
        _roadPolylinePoints = [];
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final origin = _waypoints.first;
      final destination = _waypoints.last;

      var url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_googleApiKey';

      // Add intermediate waypoints if any
      if (_waypoints.length > 2) {
        final intermediates = _waypoints
            .sublist(1, _waypoints.length - 1)
            .map((wp) => '${wp.latitude},${wp.longitude}')
            .join('|');
        url += '&waypoints=$intermediates';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final encodedPolyline =
              data['routes'][0]['overview_polyline']['points'] as String;
          final decoded = _decodePolyline(encodedPolyline);
          setState(() {
            _roadPolylinePoints = decoded;
          });
        } else {
          // Fallback to straight lines if Directions API fails
          setState(() {
            _roadPolylinePoints = List.from(_waypoints);
          });
        }
      }
    } catch (_) {
      // Fallback to straight lines
      setState(() {
        _roadPolylinePoints = List.from(_waypoints);
      });
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < _waypoints.length; i++) {
      String label;
      double hue;
      if (i == 0) {
        label = 'Start';
        hue = BitmapDescriptor.hueGreen;
      } else if (i == _waypoints.length - 1 && _waypoints.length > 1) {
        label = 'End';
        hue = BitmapDescriptor.hueRed;
      } else {
        label = 'Stop $i';
        hue = BitmapDescriptor.hueOrange;
      }

      markers.add(Marker(
        markerId: MarkerId('waypoint_$i'),
        position: _waypoints[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: label,
          snippet: 'Tap to remove',
          onTap: () => _removeWaypoint(i),
        ),
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _waypoints[i] = newPosition;
          });
          _fetchDirections();
        },
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_roadPolylinePoints.length >= 2) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _roadPolylinePoints,
          color: _primaryColor,
          width: 5,
        ),
      };
    }
    if (_waypoints.length >= 2) {
      // Fallback straight line while loading
      return {
        Polyline(
          polylineId: const PolylineId('route_straight'),
          points: _waypoints,
          color: _primaryColor.withAlpha(100),
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }
    return {};
  }

  void _addWaypoint(LatLng position) {
    setState(() {
      _waypoints.add(position);
    });
    _fetchDirections();
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
    _fetchDirections();
  }

  void _clearAllWaypoints() {
    setState(() {
      _waypoints.clear();
      _roadPolylinePoints = [];
    });
  }

  String _encodeWaypoints() {
    final list = _waypoints
        .map((wp) => {'lat': wp.latitude, 'lng': wp.longitude})
        .toList();
    return jsonEncode(list);
  }

  void _confirmRoute() {
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 points (start and end)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, _encodeWaypoints());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Route on Map'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_waypoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAllWaypoints,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _waypoints.isNotEmpty ? _waypoints.first : _bosniaCenter,
              zoom: _waypoints.isNotEmpty ? 10 : 7,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _addWaypoint,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isLoadingRoute)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                    )
                  else
                    const Icon(Icons.info_outline, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingRoute
                          ? 'Calculating road route...'
                          : _waypoints.isEmpty
                              ? 'Tap on the map to add route points'
                              : '${_waypoints.length} point${_waypoints.length == 1 ? '' : 's'} added. Drag to adjust, tap info to remove.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _confirmRoute,
                  icon: const Icon(Icons.check),
                  label: Text('Confirm Route (${_waypoints.length} pts)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}