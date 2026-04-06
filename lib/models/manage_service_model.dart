class ManageService {
  const ManageService({
    required this.categoryId,
    required this.name,
    required this.isSelected,
  });

  final int categoryId;
  final String name;
  final bool isSelected;

  // Backward compatibility for older call-sites still using `serviceId`.
  int get serviceId => categoryId;

  factory ManageService.fromJson(Map<String, dynamic> json) {
    return ManageService(
      categoryId: _toInt(
        json['categoryId'] ?? json['serviceId'] ?? json['id'],
      ),
      name: _toString(
        json['name'] ?? json['categoryName'] ?? json['title'],
      ),
      isSelected: _toBool(
        json['isSelected'] ?? json['selected'] ?? json['isActive'],
      ),
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
    required this.categories,
  });

  final bool success;
  final List<ManageService> categories;

  // Backward compatibility for older call-sites still using `services`.
  List<ManageService> get services => categories;

  factory ManageServicesApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final serviceList = <ManageService>[];

    void readList(dynamic source) {
      if (source is! List) return;
      for (final item in source) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nestedServices = map['services'];
        if (nestedServices is List && nestedServices.isNotEmpty) {
          for (final nestedItem in nestedServices) {
            if (nestedItem is Map) {
              final nestedMap = Map<String, dynamic>.from(nestedItem);
              serviceList.add(ManageService.fromJson(nestedMap));
            }
          }
          continue;
        }
        serviceList.add(ManageService.fromJson(map));
      }
    }

    if (data is List) {
      readList(data);
    } else if (data is Map) {
      final normalizedData = Map<String, dynamic>.from(data);
      readList(normalizedData['categories']);
      if (serviceList.isEmpty) {
        readList(normalizedData['services']);
      }
    }

    if (serviceList.isEmpty) {
      readList(json['categories']);
    }
    if (serviceList.isEmpty) {
      readList(json['services']);
    }

    return ManageServicesApiResponse(
      success: json['success'] == true,
      categories: serviceList,
    );
  }
}
