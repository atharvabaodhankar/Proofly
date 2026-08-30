import 'package:flutter/material.dart';
import '../data/models/certificate_model.dart';
import '../data/services/api_service.dart';

class CertificatesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<CertificateModel> _certificates = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;

  List<CertificateModel> get certificates => _certificates;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  List<CertificateModel> get filteredCertificates {
    return _certificates.where((cert) {
      final matchesSearch = cert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (cert.organizationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      if (_selectedCategory == 'All') return matchesSearch;
      return matchesSearch && cert.title.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  CertificatesProvider() {
    loadCertificates();
  }

  Future<void> loadCertificates([String? token]) async {
    _isLoading = true;
    notifyListeners();

    try {
      _certificates = await _api.getMyCertificates(token ?? 'demo_token');
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
