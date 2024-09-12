import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  const LocationPage({
    super.key,
    this.latitude,
    this.longitude,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  LatLng? _tappedPosition;
  TextEditingController _searchController = TextEditingController();

  final LatLngBounds bounds = LatLngBounds(
    LatLng(-90.0, -180.0), // Southwest corner
    LatLng(90.0, 180.0), // Northeast corner
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permissions are permanently denied.");
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition!, 15);
  }
  Future<void> _searchLocation() async {
    try {
      List<Location> locations =
          await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _tappedPosition =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
        _mapController.move(_tappedPosition!, 15);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng center =
        _currentPosition ?? LatLng(widget.latitude ?? 0, widget.longitude ?? 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Location',
              style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search location',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchLocation,
            ),
          ),
          onSubmitted: (_) => _searchLocation(),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              minZoom: 0,
              maxZoom: 20.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  _tappedPosition = point;
                });
              },
              cameraConstraint: CameraConstraint.contain(
                bounds: bounds,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.saturation,
                    ),
                    child: tileWidget,
                  );
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  if (_tappedPosition != null)
                    Marker(
                      point: _tappedPosition!,
                      child: const Icon(
                        Icons.push_pin,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Position:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Latitude: ${_currentPosition?.latitude ?? widget.latitude}',
                          style: const TextStyle(fontSize: 14),
                        ), 
                        Text(
                          'Longitude: ${_currentPosition?.longitude ?? widget.longitude}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        if (_tappedPosition != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tapped Position:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Latitude: ${_tappedPosition!.latitude}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Longitude: ${_tappedPosition!.longitude}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}