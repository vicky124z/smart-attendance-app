import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// App-wide auth/session state. Wrap the app in a ChangeNotifierProvider
/// of this class (see main.dart) and consume via context.read/watch.
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService.instance;

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    ApiClient.instance.onSessionExpired = () {
      _user = null;
      notifyListeners();
    };
  }

  Future<bool> tryRestoreSession() async {
    if (!await _authService.isLoggedIn) return false;
    try {
      _user = await _authService.fetchMe();
      notifyListeners();
      return true;
    } catch (_) {
      await _authService.logout();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        department: department,
        studentCode: studentCode,
        employeeCode: employeeCode,
        semester: semester,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
