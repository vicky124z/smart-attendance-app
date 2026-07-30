import '../models/user_model.dart';
import 'api_client.dart';

class AccountsService {
  AccountsService._();
  static final AccountsService instance = AccountsService._();

  final _api = ApiClient.instance;

  Future<List<UserModel>> getUsers({String? role, String? search}) async {
    final data = await _api.get('/accounts/users/', query: {
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = data is Map ? (data['results'] as List? ?? data as List) : data as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> getUser(String id) async {
    final data = await _api.get('/accounts/users/$id/') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Admin create student / teacher / admin.
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String role,
    String password = '',
    String phone = '',
    String? departmentId,
    String semester = '',
    String studentCode = '',
    String employeeCode = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
      if (password.isNotEmpty) 'password': password,
      if (phone.isNotEmpty) 'phone': phone,
      if (departmentId != null && departmentId.isNotEmpty) 'department': departmentId,
      if (semester.isNotEmpty) 'semester': semester,
      if (studentCode.isNotEmpty) 'student_code': studentCode,
      if (employeeCode.isNotEmpty) 'employee_code': employeeCode,
    };
    final data = await _api.post('/accounts/users/', body: body) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUser(
    String id, {
    String? name,
    String? email,
    String? phone,
    String? departmentId,
    String? semester,
    String? studentCode,
    String? employeeCode,
    String? password,
    String? role,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (departmentId != null) 'department': departmentId.isEmpty ? null : departmentId,
      if (semester != null) 'semester': semester,
      if (studentCode != null) 'student_code': studentCode,
      if (employeeCode != null) 'employee_code': employeeCode,
      if (password != null && password.isNotEmpty) 'password': password,
      if (role != null) 'role': role,
    };
    final data = await _api.patch('/accounts/users/$id/', body: body) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/accounts/users/$id/');
  }
}
