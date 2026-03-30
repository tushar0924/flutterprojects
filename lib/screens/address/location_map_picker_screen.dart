import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../../utils/toast_helper.dart';

class LocationMapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationMapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationMapPickerScreen> createState() => _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  final MapController _mapController = MapController();
  Timer? _geocodeDebounce;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _building;
  String? _street;
  String? _area;
  String? _city;
  String? _postalCode;
  bool _isLocationLoading = false;

  String get _addressTitle {
    final title = _firstNonEmpty(<String?>[_area, _city, _street, _building]);
    if (title.isNotEmpty) return title;
    return 'Selected location';
  }

  String get _addressSubtitle {
    final text = (_selectedAddress ?? '').trim();
    if (text.isNotEmpty && text != 'Updating location...') return text;
    return 'Move map to update address';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _getAddressFromCoordinates();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _getCurrentLocation();
        }
      });
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  String _firstNonEmpty(List<String?> candidates) {
    for (final value in candidates) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_selectedLocation == null) return;
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      if (mounted && placemarks.isNotEmpty) {
        final place = placemarks.first;
        final building = _firstNonEmpty(<String?>[
          place.subThoroughfare,
          place.name,
        ]);
        final street = _firstNonEmpty(<String?>[
          place.street,
          place.thoroughfare,
        ]);
        final area = _firstNonEmpty(<String?>[
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
        ]);
        final city = _firstNonEmpty(<String?>[
          place.locality,
          place.administrativeArea,
        ]);
        final pinCode = _firstNonEmpty(<String?>[place.postalCode]);

        final address = <String>[
          building,
          street,
          area,
          city,
          pinCode,
        ].where((part) => part.isNotEmpty).join(', ');

        setState(() {
          _building = building;
          _street = street;
          _area = area;
          _city = city;
          _postalCode = pinCode;
          _selectedAddress = address.trim();
        });
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppToast.showError('Please enable location services');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppToast.showError('Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _selectedLocation = newLocation);
        _mapController.move(newLocation, 16);
        await _getAddressFromCoordinates();
      }
    } catch (e) {
      AppToast.showError('Unable to get location: $e');
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  void _onMapTap(LatLng location) {
    setState(() => _selectedLocation = location);
    _getAddressFromCoordinates();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    final center = camera.center;

    setState(() {
      _selectedLocation = center;
      _selectedAddress = 'Updating location...';
    });

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _getAddressFromCoordinates();
      }
    });
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      AppToast.showError('Please select a location');
      return;
    }
    Navigator.of(context).pop({
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'address': _selectedAddress,
      'fullAddress': _selectedAddress,
      'building': _building,
      'street': _street,
      'area': _area,
      'city': _city,
      'postalCode': _postalCode,
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialLocation = _selectedLocation ??
        const LatLng(28.7041, 77.1025); // Default: New Delhi

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: 15,
              onTap: (_, point) => _onMapTap(point),
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutterprojects',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF8D97A6), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search for new area or locality...',
                              style: TextStyle(
                                color: Color(0xFF8D97A6),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on,
                    color: Color(0xFF0D9A55),
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _isLocationLoading ? null : _getCurrentLocation,
                    icon: _isLocationLoading
                        ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0D9A55),
                            ),
                          )
                        : const Icon(
                            Icons.my_location,
                            size: 18,
                            color: Color(0xFF0D9A55),
                          ),
                    label: const Text(
                      'Use Current Location',
                      style: TextStyle(
                        color: Color(0xFF0D9A55),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFA7D7BC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order will be delivered here',
                        style: TextStyle(
                          color: Color(0xFF3E4A59),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on,
                              color: Color(0xFF0D9A55),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _addressTitle,
                                  style: const TextStyle(
                                    color: Color(0xFF273444),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _addressSubtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLocationLoading ? null : _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B2239),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm & proceed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
