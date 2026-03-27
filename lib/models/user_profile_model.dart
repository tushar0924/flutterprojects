class UserProfile {
  final int? id;
  final String fullName;
  final String name;
  final String phone;
  final String role;
  final String? avatar;
  final bool isActive;

  const UserProfile({
    this.id,
    this.fullName = '',
    this.name = '',
    this.phone = '',
    this.role = '',
    this.avatar,
    this.isActive = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    return UserProfile(
      id: idValue is int
          ? idValue
          : (idValue is num ? idValue.toInt() : int.tryParse('$idValue')),
      fullName: (json['fullName'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      role: (json['role'] ?? '').toString().trim(),
      avatar: json['avatar']?.toString(),
      isActive: json['isActive'] == true,
    );
  }

  factory UserProfile.fromProfileResponse(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }

    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      return UserProfile.fromJson(user);
    }

    return UserProfile.fromJson(payload);
  }

  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    if (name.isNotEmpty) return name;
    return 'Helper';
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty || source == 'Helper') return 'H';
    return source.substring(0, 1).toUpperCase();
  }

  bool get isEmpty {
    return id == null &&
        fullName.isEmpty &&
        name.isEmpty &&
        phone.isEmpty &&
        role.isEmpty;
  }
}