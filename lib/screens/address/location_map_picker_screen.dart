import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  State<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  static const LatLng _defaultLocation = LatLng(28.7041, 77.1025);
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const MethodChannel _apiKeyChannel = MethodChannel(
    'google_maps_api_key',
  );

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  late final Future<String> _resolvedGoogleMapsApiKeyFuture =
      _resolveGoogleMapsApiKey();

  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _building;
  String? _street;
  String? _area;
  String? _city;
  String? _postalCode;
  List<_PlaceSuggestion> _suggestions = <_PlaceSuggestion>[];

  bool _isLocationLoading = false;
  bool _isSearchingPlaces = false;
  bool _isResolvingAddress = false;

  bool get _supportsGoogleMaps =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  String get _addressTitle {
    final title = _firstNonEmpty(<String?>[_area, _city, _street, _building]);
    if (title.isNotEmpty) return title;
    return 'Selected location';
  }

  String get _addressSubtitle {
    final text = (_selectedAddress ?? '').trim();
    if (text.isNotEmpty && text != 'Updating location...') return text;
    return 'Move the map or search for an area';
  }

  bool get _canConfirmLocation {
    final address = (_selectedAddress ?? '').trim();
    final hasResolvedAddress =
        address.isNotEmpty && address != 'Updating location...';

    return _selectedLocation != null &&
        !_isLocationLoading &&
        !_isResolvingAddress &&
        hasResolvedAddress;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reverseGeocode(_selectedLocation!);
        }
      });
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
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _firstNonEmpty(List<String?> candidates) {
    for (final value in candidates) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<String> _resolveGoogleMapsApiKey() async {
    if (_googleMapsApiKey.isNotEmpty) {
      return _googleMapsApiKey;
    }

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      final nativeKey = await _apiKeyChannel.invokeMethod<String>(
        'getAndroidMapsApiKey',
      );
      if ((nativeKey ?? '').trim().isNotEmpty) {
        return nativeKey!.trim();
      }
    }

    return '';
  }

  Future<String> _requireGoogleMapsApiKey() async {
    final apiKey = await _resolvedGoogleMapsApiKeyFuture;
    if (apiKey.trim().isEmpty) {
      AppToast.showError(
        'Set GOOGLE_MAPS_API_KEY in android/local.properties and rebuild the app',
      );
    }
    return apiKey.trim();
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    setState(() {});

    final query = _searchController.text.trim();
    _searchDebounce?.cancel();

    if (query.length < 3) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = <_PlaceSuggestion>[]);
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchSuggestions(query);
      }
    });
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected API response');
  }

  Future<void> _fetchSuggestions(String query) async {
    final apiKey = await _requireGoogleMapsApiKey();
    if (apiKey.isEmpty) {
      return;
    }

    setState(() => _isSearchingPlaces = true);
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        <String, String>{
          'input': query,
          'key': apiKey,
          'language': 'en',
        },
      );
      final body = await _getJson(uri);
      if (!mounted) return;

      final status = (body['status'] ?? '').toString();
      if (status == 'OK') {
        final predictions = (body['predictions'] as List? ?? <dynamic>[])
            .whereType<Map>()
            .map(
              (item) =>
                  _PlaceSuggestion.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        setState(() => _suggestions = predictions);
      } else if (status == 'ZERO_RESULTS') {
        setState(() => _suggestions = <_PlaceSuggestion>[]);
      } else {
        throw Exception((body['error_message'] ?? status).toString());
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError('Unable to load search suggestions: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
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
      await _setSelectedLocation(newLocation, moveCamera: true);
      await _reverseGeocode(newLocation);
    } catch (e) {
      AppToast.showError('Unable to get location: $e');
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _setSelectedLocation(
    LatLng location, {
    bool moveCamera = false,
  }) async {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _selectedAddress = 'Updating location...';
      _isResolvingAddress = true;
    });

    if (moveCamera && _mapController.isCompleted) {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16),
        ),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    final location = position.target;
    _geocodeDebounce?.cancel();

    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _selectedAddress = 'Updating location...';
      _isResolvingAddress = true;
    });

    _geocodeDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _reverseGeocode(location);
      }
    });
  }

  void _onMarkerDragEnd(LatLng location) {
    _geocodeDebounce?.cancel();
    _setSelectedLocation(location).then((_) {
      if (mounted) {
        _reverseGeocode(location);
      }
    });
  }

  Future<void> _reverseGeocode(LatLng location) async {
    final apiKey = await _requireGoogleMapsApiKey();
    if (apiKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isResolvingAddress = false;
        _selectedAddress = _selectedAddress?.isNotEmpty == true
            ? _selectedAddress
            : 'Selected location';
      });
      return;
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        <String, String>{
          'latlng': '${location.latitude},${location.longitude}',
          'key': apiKey,
          'language': 'en',
        },
      );
      final body = await _getJson(uri);
      if (!mounted) return;

      final status = (body['status'] ?? '').toString();
      if (status != 'OK') {
        final message = (body['error_message'] ?? status).toString();
        throw Exception(
          message.isEmpty ? 'Unable to resolve address' : message,
        );
      }

      final results = body['results'] as List? ?? <dynamic>[];
      if (results.isEmpty) {
        throw Exception('No address found for the selected location');
      }

      final details = _AddressDetails.fromGoogleGeocode(
        Map<String, dynamic>.from(results.first as Map),
        location,
      );
      if (!mounted) return;

      _applyAddressDetails(details);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress = _selectedAddress?.isNotEmpty == true
            ? _selectedAddress
            : 'Selected location';
        _isResolvingAddress = false;
      });
    }
  }

  Future<void> _openSuggestion(_PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    _searchDebounce?.cancel();

    final apiKey = await _requireGoogleMapsApiKey();
    if (apiKey.isEmpty) {
      return;
    }

    setState(() => _isSearchingPlaces = true);
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        <String, String>{
          'place_id': suggestion.placeId,
          'fields': 'formatted_address,geometry,address_component,name',
          'key': apiKey,
          'language': 'en',
        },
      );
      final body = await _getJson(uri);
      if (!mounted) return;

      final status = (body['status'] ?? '').toString();
      if (status != 'OK') {
        throw Exception((body['error_message'] ?? status).toString());
      }

      final result = Map<String, dynamic>.from(body['result'] as Map);
      final geometry = Map<String, dynamic>.from(result['geometry'] as Map);
      final location = Map<String, dynamic>.from(geometry['location'] as Map);
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      final pickedLocation = LatLng(lat, lng);
      final details = _AddressDetails.fromPlaceDetails(result, pickedLocation);

      _searchController.text = details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : suggestion.description;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );

      setState(() {
        _suggestions = <_PlaceSuggestion>[];
      });

      await _setSelectedLocation(pickedLocation, moveCamera: true);
      _applyAddressDetails(details, updateSearchText: false);
    } catch (e) {
      if (mounted) {
        AppToast.showError('Unable to open place: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlaces = false);
      }
    }
  }

  void _applyAddressDetails(
    _AddressDetails details, {
    bool updateSearchText = false,
  }) {
    if (!mounted) return;

    setState(() {
      _building = details.building;
      _street = details.street;
      _area = details.area;
      _city = details.city;
      _postalCode = details.postalCode;
      _selectedAddress = details.formattedAddress;
      _isResolvingAddress = false;
    });

    if (updateSearchText) {
      _searchController.text = details.formattedAddress;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  void _confirmLocation() {
    if (_isResolvingAddress) {
      AppToast.showError('Please wait while we resolve the address');
      return;
    }

    if (_selectedLocation == null) {
      AppToast.showError('Please select a location');
      return;
    }

    final address = (_selectedAddress ?? '').trim();
    if (address.isEmpty || address == 'Updating location...') {
      AppToast.showError('Please wait until address resolution completes');
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

  Widget _buildUnsupportedPlatformView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pick Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Google Maps picker is supported on Android, iOS, and web.\nRun this screen on a supported device to search and confirm an address.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF475467),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Color(0xFF101828), fontSize: 14),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            _fetchSuggestions(trimmed);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search for area, landmark, or building',
          hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF98A2B3)),
          suffixIcon: _isSearchingPlaces
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _suggestions = <_PlaceSuggestion>[]);
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF98A2B3)),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, color: Color(0xFF0D9A55)),
            title: Text(
              suggestion.mainText.isNotEmpty
                  ? suggestion.mainText
                  : suggestion.description,
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: suggestion.secondaryText.isNotEmpty
                ? Text(
                    suggestion.secondaryText,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  )
                : null,
            onTap: () => _openSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    final initialLocation = _selectedLocation ?? _defaultLocation;
    final markerLocation = _selectedLocation;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialLocation, zoom: 15),
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
        if (_selectedLocation != null) {
          controller.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _selectedLocation!, zoom: 16),
            ),
          );
        }
      },
      onCameraMove: _onCameraMove,
      onTap: (location) {
        _geocodeDebounce?.cancel();
        _setSelectedLocation(location);
        _reverseGeocode(location);
      },
      markers: markerLocation == null
          ? <Marker>{}
          : <Marker>{
              Marker(
                markerId: const MarkerId('selected_location'),
                position: markerLocation,
                draggable: true,
                onDragEnd: _onMarkerDragEnd,
                infoWindow: const InfoWindow(title: 'Selected location'),
              ),
            },
    );
  }

  Widget _buildBottomSheet() {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInset = keyboardInset > 0 ? keyboardInset : systemBottomInset;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 14 + bottomInset,
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
                            _isResolvingAddress
                                ? 'Resolving address...'
                                : _addressSubtitle,
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
                    onPressed: _canConfirmLocation ? _confirmLocation : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsGoogleMaps) {
      return _buildUnsupportedPlatformView();
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSearchBar()),
                    ],
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSuggestionsList(),
                  ],
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              // child: Container(
              //   width: 54,
              //   height: 54,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     shape: BoxShape.circle,
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withValues(alpha: 0.18),
              //         blurRadius: 12,
              //       ),
              //     ],
              //   ),
              //
              // ),
            ),
          ),
          _buildBottomSheet(),
        ],
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const _PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting = json['structured_formatting'];
    final formatted = formatting is Map
        ? Map<String, dynamic>.from(formatting)
        : <String, dynamic>{};

    return _PlaceSuggestion(
      placeId: (json['place_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      mainText: (formatted['main_text'] ?? '').toString(),
      secondaryText: (formatted['secondary_text'] ?? '').toString(),
    );
  }
}

class _AddressDetails {
  final String building;
  final String street;
  final String area;
  final String city;
  final String postalCode;
  final String formattedAddress;
  final LatLng location;

  const _AddressDetails({
    required this.building,
    required this.street,
    required this.area,
    required this.city,
    required this.postalCode,
    required this.formattedAddress,
    required this.location,
  });

  factory _AddressDetails.fromPlaceDetails(
    Map<String, dynamic> result,
    LatLng location,
  ) {
    final components = (result['address_components'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final building = _pickComponent(components, <String>[
      'street_number',
      'premise',
      'subpremise',
      'floor',
      'room',
    ]);
    final streetName = _pickComponent(components, <String>['route']);
    final street = [
      building,
      streetName,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    final area = _pickComponent(components, <String>[
      'sublocality_level_1',
      'sublocality',
      'neighborhood',
      'locality',
    ]);
    final city = _pickComponent(components, <String>[
      'locality',
      'administrative_area_level_2',
      'administrative_area_level_1',
    ]);
    final postalCode = _pickComponent(components, <String>['postal_code']);

    final formattedAddress = (result['formatted_address'] ?? '')
        .toString()
        .trim();

    final fallbackAddress = <String>[
      building,
      streetName,
      area,
      city,
      postalCode,
    ].where((value) => value.isNotEmpty).join(', ');

    return _AddressDetails(
      building: building,
      street: street.isNotEmpty ? street : streetName,
      area: area,
      city: city,
      postalCode: postalCode,
      formattedAddress: formattedAddress.isNotEmpty
          ? formattedAddress
          : fallbackAddress,
      location: location,
    );
  }

  factory _AddressDetails.fromGoogleGeocode(
    Map<String, dynamic> result,
    LatLng location,
  ) {
    final components = (result['address_components'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final building = _pickComponent(components, <String>[
      'street_number',
      'premise',
      'subpremise',
      'floor',
      'room',
    ]);
    final streetName = _pickComponent(components, <String>['route']);
    final street = [
      building,
      streetName,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    final area = _pickComponent(components, <String>[
      'sublocality_level_1',
      'sublocality',
      'neighborhood',
      'locality',
    ]);
    final city = _pickComponent(components, <String>[
      'locality',
      'administrative_area_level_2',
      'administrative_area_level_1',
    ]);
    final postalCode = _pickComponent(components, <String>['postal_code']);

    final formattedAddress = (result['formatted_address'] ?? '')
        .toString()
        .trim();

    final fallbackAddress = <String>[
      building,
      streetName,
      area,
      city,
      postalCode,
    ].where((value) => value.isNotEmpty).join(', ');

    return _AddressDetails(
      building: building,
      street: street.isNotEmpty ? street : streetName,
      area: area,
      city: city,
      postalCode: postalCode,
      formattedAddress: formattedAddress.isNotEmpty
          ? formattedAddress
          : fallbackAddress,
      location: location,
    );
  }

  static String _pickComponent(
    List<Map<String, dynamic>> components,
    List<String> desiredTypes,
  ) {
    for (final component in components) {
      final types = (component['types'] as List? ?? <dynamic>[])
          .map((value) => value.toString())
          .toList();
      final matches = types.any(desiredTypes.contains);
      if (matches) {
        final value = (component['long_name'] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }
}
