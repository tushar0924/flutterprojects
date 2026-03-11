import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class UserRepository {
  final ApiClient _client;

  UserRepository([ApiClient? client]) : _client = client ?? apiClient;

  /// GET /api/user/profile — Requires JWT
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.get(UserApiEndpoint.profile);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  /// PUT /api/user/profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    final res = await _client.put(UserApiEndpoint.profile, data: data);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  /// POST /api/user/register-helper — Register as helper partner
  Future<Map<String, dynamic>> registerHelper() async {
    final res = await _client.post(UserApiEndpoint.registerHelper);
    return (res.data as Map<String, dynamic>?) ?? {};
  }
}
