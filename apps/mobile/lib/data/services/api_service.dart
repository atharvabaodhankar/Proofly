import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/certificate_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  String baseUrl = ApiConstants.baseUrl;

  ApiService({String? customUrl}) {
    if (customUrl != null) baseUrl = customUrl;
  }

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  dynamic _safeDecode(http.Response res) {
    if (kDebugMode) {
      print('🌐 API [${res.request?.method}] ${res.request?.url} -> Status: ${res.statusCode}');
      print('📦 Body: ${res.body.length > 300 ? "${res.body.substring(0, 300)}..." : res.body}');
    }

    if (res.body.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        final errMsg = decoded is Map
            ? (decoded['message'] ?? decoded['error'] ?? 'Request failed (${res.statusCode})')
            : 'Request failed (${res.statusCode})';
        throw Exception(errMsg);
      }
      return decoded;
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) {
        rethrow;
      }
      throw Exception('Server returned status ${res.statusCode} (Non-JSON response: ${res.body.length > 80 ? res.body.substring(0, 80) : res.body})');
    }
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl${ApiConstants.login}'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Auth: Register
  Future<Map<String, dynamic>> register(
      String email, String password, String name, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl${ApiConstants.register}'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      }),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Auth: Get Current User Profile & Organization
  Future<Map<String, dynamic>> getMe(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.me}'),
      headers: _headers(token),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Recipient: Get My Certificates
  Future<List<CertificateModel>> getMyCertificates(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.myCertificates}'),
      headers: _headers(token),
    );
    final data = _safeDecode(res) as Map<String, dynamic>;
    final list = data['certificates'] as List? ?? [];
    return list.map((c) => CertificateModel.fromJson(c)).toList();
  }

  // Issuer: Get Organization Issued Certificates
  Future<List<CertificateModel>> getOrgCertificates(String orgId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/certificates/organizations/$orgId/certificates'),
      headers: _headers(token),
    );
    final data = _safeDecode(res) as Map<String, dynamic>;
    final list = data['certificates'] as List? ?? [];
    return list.map((c) => CertificateModel.fromJson(c)).toList();
  }

  // Public: Live Blockchain Verification
  Future<Map<String, dynamic>> verifyCertificate(String query) async {
    // Sanitize query in case full URL was passed in
    String cleanQuery = query.trim();
    if (cleanQuery.contains('/verify/')) {
      cleanQuery = cleanQuery.split('/verify/').last.split('?').first;
    }

    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.verifyCertificate}/$cleanQuery'),
      headers: _headers(),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Issuer: Issue New Certificate (PDF generation + AWS S3 + Polygon Amoy)
  Future<Map<String, dynamic>> issueCertificate(
      String orgId, Map<String, dynamic> payload, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/certificates/organizations/$orgId/certificates'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Claim: Claim Certificate with Token
  Future<Map<String, dynamic>> claimCertificate(String claimToken, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/claims/$claimToken/claim'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }

  // Create Organization
  Future<Map<String, dynamic>> createOrganization(String name, String slug, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/organizations'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'slug': slug}),
    );
    return _safeDecode(res) as Map<String, dynamic>;
  }
}
