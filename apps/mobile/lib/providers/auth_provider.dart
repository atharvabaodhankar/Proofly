import 'package:flutter/material.dart';
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
  bool get isAuthenticated => _token != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Default demo user setup for immediate high-end UX
    _user = UserModel(
      id: 'demo-user',
      name: 'Alex Rivera',
      email: 'alex.rivera@techinst.edu',
      role: 'org_admin',
      walletAddress: '0x4F...9A2',
    );
    _activeOrg = OrganizationModel(
      id: '522dfb25-39fb-4846-b5d0-bcb3717fe5ce',
      name: 'Tech Institute Global',
      slug: 'tech-institute',
    );
    _token = 'demo_token';
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(email, password);
      if (res['token'] != null) {
        _token = res['token'];
        _user = UserModel.fromJson(res['user']);
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
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
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
