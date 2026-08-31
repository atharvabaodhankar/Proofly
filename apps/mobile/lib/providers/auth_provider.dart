import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/models/organization_model.dart';
import '../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  String? _token;
  OrganizationModel? _activeOrg;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  OrganizationModel? get activeOrg => _activeOrg;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      if (savedToken != null) {
        _token = savedToken;
        final me = await _api.getMe(savedToken);
        if (me['user'] != null) {
          _user = UserModel.fromJson(me['user']);
          final orgs = me['organizations'] as List? ?? [];
          if (orgs.isNotEmpty) {
            _activeOrg = OrganizationModel.fromJson(orgs.first);
          }
          notifyListeners();
        }
      }
    } catch (_) {
      _token = null;
      _user = null;
      _activeOrg = null;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(email, password);
      if (res['token'] != null && res['user'] != null) {
        _token = res['token'];
        _user = UserModel.fromJson(res['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        // Fetch full profile and active organizations
        try {
          final me = await _api.getMe(_token!);
          final orgs = me['organizations'] as List? ?? [];
          if (orgs.isNotEmpty) {
            _activeOrg = OrganizationModel.fromJson(orgs.first);
          }
        } catch (_) {}

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['error'] ?? 'Authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? orgName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.register(email, password, name, role);
      if (res['token'] != null && res['user'] != null) {
        _token = res['token'];
        _user = UserModel.fromJson(res['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        // If issuer and orgName provided, create the organization
        if (role == 'org_admin' || role == 'org_issuer') {
          try {
            final slug = (orgName ?? name).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
            final orgRes = await _api.createOrganization(orgName ?? '$name Org', slug, _token!);
            if (orgRes['organization'] != null) {
              _activeOrg = OrganizationModel.fromJson(orgRes['organization']);
            }
          } catch (_) {}
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _user = null;
    _token = null;
    _activeOrg = null;
    notifyListeners();
  }

  void setActiveOrg(OrganizationModel org) {
    _activeOrg = org;
    notifyListeners();
  }
}
