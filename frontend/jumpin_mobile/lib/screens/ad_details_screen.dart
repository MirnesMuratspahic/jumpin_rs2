import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/ad.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';

const String _googleApiKey = 'AIzaSyC-0_DaR3ubLN3d7Sz6jS39RdmolZOLz4Y';

class AdDetailsScreen extends StatefulWidget {
  final Ad ad;
  final AuthProvider authProvider;

  const AdDetailsScreen({
    super.key,
    required this.ad,
    required this.authProvider,
  });

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  final _requestProvider = RequestProvider();
  bool _isSendingRequest = false;
  List<LatLng> _roadPolylinePoints = [];
  List<LatLng> _routeWaypoints = [];
  bool _isLoadingRoute = true;
  int _currentImageIndex = 0;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _requestProvider.setToken(widget.authProvider.token);
    _fetchRoadRoute();
  }

  Future<void> _fetchRoadRoute() async {
    final ad = widget.ad;
    List<LatLng> waypoints = [];
    if (ad.routeCoordinates != null && ad.routeCoordinates!.isNotEmpty) {
      try {
        final List<dynamic> coords = jsonDecode(ad.routeCoordinates!);
        for (var coord in coords) {
          waypoints.add(LatLng(
            (coord['lat'] as num).toDouble(),
            (coord['lng'] as num).toDouble(),
          ));
        }
      } catch (_) {}
    }
    // Fallback: use start/end coordinates if no routeCoordinates
    if (waypoints.length < 2 &&
        ad.latitude != null && ad.longitude != null &&
        ad.latitudeEnd != null && ad.longitudeEnd != null) {
      waypoints = [
        LatLng(ad.latitude!, ad.longitude!),
        LatLng(ad.latitudeEnd!, ad.longitudeEnd!),
      ];
    }

    setState(() {
      _routeWaypoints = waypoints;
    });

    if (waypoints.length < 2) {
      setState(() => _isLoadingRoute = false);
      return;
    }

    try {
      final origin = waypoints.first;
      final destination = waypoints.last;
      var url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_googleApiKey';

      if (waypoints.length > 2) {
        final intermediates = waypoints
            .sublist(1, waypoints.length - 1)
            .map((wp) => '${wp.latitude},${wp.longitude}')
            .join('|');
        url += '&waypoints=$intermediates';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final encoded = data['routes'][0]['overview_polyline']['points'] as String;
          setState(() {
            _roadPolylinePoints = _decodePolyline(encoded);
          });
        }
      }
    } catch (_) {}

    setState(() => _isLoadingRoute = false);
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

  Color get _adTypeColor {
    switch (widget.ad.adType.toLowerCase()) {
      case 'route':
        return Colors.blue[700]!;
      case 'carrental':
      case 'car':
        return Colors.orange[700]!;
      case 'apartmentrental':
      case 'apartment':
        return Colors.green[700]!;
      default:
        return _primaryColor;
    }
  }

  IconData get _adTypeIcon {
    switch (widget.ad.adType.toLowerCase()) {
      case 'route':
        return Icons.route;
      case 'carrental':
      case 'car':
        return Icons.directions_car;
      case 'apartmentrental':
      case 'apartment':
        return Icons.apartment;
      default:
        return Icons.article;
    }
  }

  Future<void> _sendRequest() async {
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a reservation request for "${widget.ad.title}"?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'Add a message to the owner...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
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
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSendingRequest = true;
    });

    final userId = widget.authProvider.currentUser?.id;
    if (userId == null) return;

    final success = await _requestProvider.sendRequest(
      senderId: userId,
      adId: widget.ad.id,
      message: messageController.text.isNotEmpty ? messageController.text : null,
    );

    setState(() {
      _isSendingRequest = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send the request. You may already have a pending request for this ad.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final isOwnAd = widget.authProvider.currentUser?.id == ad.userId;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(ad.adTypeDisplay),
        backgroundColor: _adTypeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image carousel or single image
            _buildImageHeader(ad),

            // Title and Price
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _adTypeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_adTypeIcon, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              ad.adTypeDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ad.isVipOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.price != null
                        ? '${ad.price!.toStringAsFixed(2)} KM'
                        : 'Price on request',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  if (ad.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Posted ${DateFormat('dd MMM yyyy').format(ad.createdAt!)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Description
            if (ad.description != null && ad.description!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ad.description!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Type-specific details
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSpecificDetails(ad),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Map section
            _buildMapSection(ad),

            const SizedBox(height: 8),

            // Owner info
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Posted by',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        child: ad.userProfileImage != null
                            ? ClipOval(
                                child: Image.network(
                                  ad.userProfileImage!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.grey[600],
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ad.userName ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (ad.isVipOwner) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                          if (ad.userRating != null && ad.userRating! > 0)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ad.userRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: !isOwnAd
          ? Container(
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
                child: ElevatedButton(
                  onPressed: _isSendingRequest ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSendingRequest
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Send Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildImageHeader(Ad ad) {
    final hasImages = ad.images != null && ad.images!.isNotEmpty;
    final hasSingleImage = ad.imageUrl != null && ad.imageUrl!.isNotEmpty;

    if (hasImages && ad.images!.length > 1) {
      // Multi-image carousel
      return SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: ad.images!.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  ad.images![index].imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: _adTypeColor.withAlpha(40),
                    child: Center(
                      child: Icon(_adTypeIcon, size: 80, color: _adTypeColor),
                    ),
                  ),
                );
              },
            ),
            // Dot indicators
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(ad.images!.length, (index) {
                  return Container(
                    width: _currentImageIndex == index ? 10 : 8,
                    height: _currentImageIndex == index ? 10 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withAlpha(120),
                    ),
                  );
                }),
              ),
            ),
            // Image counter
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${ad.images!.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Single image or fallback
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_adTypeColor.withAlpha(40), _adTypeColor.withAlpha(80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: hasSingleImage
          ? Image.network(
              ad.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(_adTypeIcon, size: 80, color: _adTypeColor),
              ),
            )
          : Center(
              child: Icon(_adTypeIcon, size: 80, color: _adTypeColor),
            ),
    );
  }

  Widget _buildMapSection(Ad ad) {
    // Use waypoints parsed by _fetchRoadRoute (stored in state)
    final waypoints = _routeWaypoints;

    // Determine if we have any coordinates to show
    final bool hasRouteWaypoints = waypoints.isNotEmpty;
    final bool hasSingleCoordinate =
        ad.latitude != null && ad.longitude != null;
    final bool hasMapData = hasRouteWaypoints || hasSingleCoordinate;

    if (!hasMapData) {
      // Show placeholder if no coordinates
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      ad.locationDisplay.isNotEmpty
                          ? ad.locationDisplay
                          : 'Location not specified',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build markers
    final markers = <Marker>{};
    LatLng cameraTarget;
    double zoom;

    // Collect all points for bounds calculation
    List<LatLng> allPoints = [];

    if (hasRouteWaypoints) {
      for (int i = 0; i < waypoints.length; i++) {
        double hue;
        String label;
        if (i == 0) {
          hue = BitmapDescriptor.hueGreen;
          label = ad.locationFrom ?? 'Start';
        } else if (i == waypoints.length - 1 && waypoints.length > 1) {
          hue = BitmapDescriptor.hueRed;
          label = ad.locationTo ?? 'End';
        } else {
          hue = BitmapDescriptor.hueOrange;
          label = 'Stop $i';
        }
        markers.add(Marker(
          markerId: MarkerId('wp_$i'),
          position: waypoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: label),
        ));
      }
      allPoints.addAll(waypoints);
      if (_roadPolylinePoints.isNotEmpty) {
        allPoints.addAll(_roadPolylinePoints);
      }
      // Fallback center
      double avgLat = waypoints.map((w) => w.latitude).reduce((a, b) => a + b) / waypoints.length;
      double avgLng = waypoints.map((w) => w.longitude).reduce((a, b) => a + b) / waypoints.length;
      cameraTarget = LatLng(avgLat, avgLng);
      zoom = 9;
    } else {
      cameraTarget = LatLng(ad.latitude!, ad.longitude!);
      zoom = 13;
      markers.add(Marker(
        markerId: const MarkerId('location'),
        position: cameraTarget,
        infoWindow: InfoWindow(
          title: ad.location ?? ad.apartmentAddress ?? ad.title,
        ),
      ));
    }

    // Build polylines for routes
    final polylines = <Polyline>{};
    if (hasRouteWaypoints && waypoints.length >= 2) {
      final polylinePoints = _roadPolylinePoints.isNotEmpty
          ? _roadPolylinePoints
          : waypoints;
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: _primaryColor,
        width: 5,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (hasRouteWaypoints) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${waypoints.length} stops',
                    style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: _isLoadingRoute && hasRouteWaypoints
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: _primaryColor),
                          const SizedBox(height: 8),
                          Text('Loading route...', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    )
                  : GoogleMap(
                      key: ValueKey('map_${_roadPolylinePoints.length}'),
                      initialCameraPosition: CameraPosition(
                        target: cameraTarget,
                        zoom: zoom,
                      ),
                      markers: markers,
                      polylines: polylines,
                      onMapCreated: (controller) {
                        if (allPoints.length >= 2) {
                          double minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
                          double maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
                          double minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
                          double maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
                          final bounds = LatLngBounds(
                            southwest: LatLng(minLat, minLng),
                            northeast: LatLng(maxLat, maxLng),
                          );
                          Future.delayed(const Duration(milliseconds: 300), () {
                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 50),
                            );
                          });
                        }
                      },
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      liteModeEnabled: false,
                    ),
            ),
          ),
          if (ad.locationDisplay.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ad.locationDisplay,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSpecificDetails(Ad ad) {
    switch (ad.adType.toLowerCase()) {
      case 'route':
        return _buildRouteDetails(ad);
      case 'carrental':
      case 'car':
        return _buildCarDetails(ad);
      case 'apartmentrental':
      case 'apartment':
        return _buildApartmentDetails(ad);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRouteDetails(Ad ad) {
    return Column(
      children: [
        _buildDetailRow(Icons.trip_origin, 'From', ad.locationFrom ?? 'N/A'),
        _buildDetailRow(Icons.location_on, 'To', ad.locationTo ?? 'N/A'),
        if (ad.dateAvailable != null)
          _buildDetailRow(Icons.calendar_today, 'Date', ad.dateAvailable!),
        if (ad.timeAvailable != null)
          _buildDetailRow(Icons.access_time, 'Time', ad.timeAvailable!),
      ],
    );
  }

  Widget _buildCarDetails(Ad ad) {
    return Column(
      children: [
        if (ad.carBrand != null)
          _buildDetailRow(Icons.directions_car, 'Brand', ad.carBrand!),
        if (ad.carModel != null)
          _buildDetailRow(Icons.car_repair, 'Model', ad.carModel!),
        if (ad.carYear != null)
          _buildDetailRow(
              Icons.date_range, 'Year', ad.carYear!.toString()),
        if (ad.carSeats != null)
          _buildDetailRow(
              Icons.event_seat, 'Seats', ad.carSeats!.toString()),
        if (ad.fuelType != null)
          _buildDetailRow(Icons.local_gas_station, 'Fuel', ad.fuelType!),
        if (ad.location != null)
          _buildDetailRow(Icons.location_on, 'Location', ad.location!),
        if (ad.dateAvailable != null)
          _buildDetailRow(Icons.calendar_today, 'Available', ad.dateAvailable!),
      ],
    );
  }

  Widget _buildApartmentDetails(Ad ad) {
    return Column(
      children: [
        if (ad.apartmentAddress != null)
          _buildDetailRow(Icons.home, 'Address', ad.apartmentAddress!),
        if (ad.apartmentRooms != null)
          _buildDetailRow(
              Icons.meeting_room, 'Rooms', ad.apartmentRooms!.toString()),
        if (ad.apartmentArea != null)
          _buildDetailRow(Icons.square_foot, 'Area',
              '${ad.apartmentArea!.toStringAsFixed(1)} m2'),
        if (ad.location != null)
          _buildDetailRow(Icons.location_city, 'City', ad.location!),
        if (ad.dateAvailable != null)
          _buildDetailRow(Icons.calendar_today, 'Available', ad.dateAvailable!),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _adTypeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: _adTypeColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
