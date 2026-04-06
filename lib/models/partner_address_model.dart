class PartnerAddressModel {
  const PartnerAddressModel({
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final String city;
  final String pinCode;
  final double? latitude;
  final double? longitude;

  factory PartnerAddressModel.empty() {
    return const PartnerAddressModel(
      address: '',
      city: '',
      pinCode: '',
      latitude: null,
      longitude: null,
    );
  }

  factory PartnerAddressModel.fromPayload(Map<String, dynamic> payload) {
    final source = _extractAddressSource(payload);

    return PartnerAddressModel(
      address: _extractAddressText(source),
      city: _extractString(source, const ['city', 'district']),
      pinCode: _extractString(source, const [
        'pinCode',
        'pincode',
        'postalCode',
      ]),
      latitude: _toNullableDouble(source['latitude'] ?? source['lat']),
      longitude: _toNullableDouble(
        source['longitude'] ?? source['lng'] ?? source['lon'],
      ),
    );
  }

  Map<String, dynamic> toPutPayload() {
    final payload = <String, dynamic>{
      'address': address,
      'city': 'jaipur',
      'pinCode': pinCode,
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    return payload;
  }

  PartnerAddressModel copyWith({
    String? address,
    String? city,
    String? pinCode,
    double? latitude,
    double? longitude,
  }) {
    return PartnerAddressModel(
      address: address ?? this.address,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static Map<String, dynamic> _extractAddressSource(
    Map<String, dynamic> payload,
  ) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final partner = data['partner'];
      if (partner is Map<String, dynamic>) return partner;
      final address = data['address'];
      if (address is Map<String, dynamic>) return address;
      return data;
    }

    final address = payload['address'];
    if (address is Map<String, dynamic>) return address;

    return payload;
  }

  static String _extractAddressText(Map<String, dynamic> source) {
    final candidates = [
      source['address'],
      source['fullAddress'],
      source['serviceArea'],
      source['line1'],
      source['street'],
    ];

    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }

    final primitiveParts = source.values
        .where((v) => v is String || v is num)
        .map((v) => v.toString().trim())
        .where((v) => v.isNotEmpty)
        .toList();

    if (primitiveParts.isEmpty) return '';
    return primitiveParts.join(', ');
  }

  static String _extractString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return '';
  }
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
