class ManageService {
  const ManageService({
    required this.serviceId,
    required this.name,
    required this.isSelected,
  });

  final int serviceId;
  final String name;
  final bool isSelected;

  factory ManageService.fromJson(Map<String, dynamic> json) {
    return ManageService(
      serviceId: _toInt(json['serviceId']),
      name: _toString(json['name']),
      isSelected: _toBool(json['isSelected']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _toString(dynamic value, {String fallback = ''}) {
    if (value is String) return value.trim();
    if (value == null) return fallback;
    return value.toString().trim();
  }
}

class ManageServicesApiResponse {
  const ManageServicesApiResponse({
    required this.success,
    required this.services,
  });

  final bool success;
  final List<ManageService> services;

  factory ManageServicesApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? [];
    final serviceList = <ManageService>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          serviceList.add(ManageService.fromJson(item));
        }
      }
    }

    return ManageServicesApiResponse(
      success: json['success'] == true,
      services: serviceList,
    );
  }
}
