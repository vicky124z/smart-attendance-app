import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Handles login / registration / current-user retrieval against the
/// Django backend and persists JWTs via [TokenStorage].
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _api = ApiClient.instance;
  final _storage = TokenStorage.instance;

  Future<UserModel> login({required String email, required String password}) async {
    final data = await _api.post(
      '/accounts/auth/login/',
      body: {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    await _storage.saveTokens(access: data['access'], refresh: data['refresh']);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String phone = '',
    String? department,
    String? studentCode,
    String? employeeCode,
    String? semester,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': userRoleToApiString(role),
      'phone': phone,
      if (department != null) 'department': department,
      if (studentCode != null) 'student_code': studentCode,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (semester != null) 'semester': semester,
    };
    final data = await _api.post('/accounts/auth/register/', body: body, auth: false) as Map<String, dynamic>;
    await _storage.saveTokens(access: data['access'], refresh: data['refresh']);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> fetchMe() async {
    final data = await _api.get('/accounts/me/') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await _api.post('/accounts/auth/change-password/', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<bool> get isLoggedIn async => (await _storage.accessToken) != null;

  Future<void> logout() async {
    await _storage.clear();
  }
}
