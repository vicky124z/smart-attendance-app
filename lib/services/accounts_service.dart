import '../models/user_model.dart';
import 'api_client.dart';

/// Admin-only user management (list/search students & teachers).
class AccountsService {
  AccountsService._internal();
  static final AccountsService instance = AccountsService._internal();

  final _api = ApiClient.instance;

  Future<List<UserModel>> getUsers({String? role, String? search}) async {
    final data = await _api.get('/accounts/users/', query: {
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final results = (data is Map<String, dynamic>) ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
