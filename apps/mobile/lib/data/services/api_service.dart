import 'dart:convert';
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

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl${ApiConstants.login}'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Login failed');
    }
    return data;
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
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Registration failed');
    }
    return data;
  }

  // Auth: Get Current User Profile & Organization
  Future<Map<String, dynamic>> getMe(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.me}'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to get profile');
    }
    return data;
  }

  // Recipient: Get My Certificates
  Future<List<CertificateModel>> getMyCertificates(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.myCertificates}'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to fetch certificates');
    }
    final list = data['certificates'] as List? ?? [];
    return list.map((c) => CertificateModel.fromJson(c)).toList();
  }

  // Issuer: Get Organization Issued Certificates
  Future<List<CertificateModel>> getOrgCertificates(String orgId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/certificates/organizations/$orgId/certificates'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to fetch issued certificates');
    }
    final list = data['certificates'] as List? ?? [];
    return list.map((c) => CertificateModel.fromJson(c)).toList();
  }

  // Public: Live Blockchain Verification
  Future<Map<String, dynamic>> verifyCertificate(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiConstants.verifyCertificate}/$query'),
      headers: _headers(),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['message'] ?? data['error'] ?? 'Certificate verification failed');
    }
    return data;
  }

  // Issuer: Issue New Certificate (PDF generation + AWS S3 + Polygon Amoy)
  Future<Map<String, dynamic>> issueCertificate(
      String orgId, Map<String, dynamic> payload, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/certificates/organizations/$orgId/certificates'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to issue certificate');
    }
    return data;
  }

  // Claim: Claim Certificate with Token
  Future<Map<String, dynamic>> claimCertificate(String claimToken, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/claims/$claimToken/claim'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to claim certificate');
    }
    return data;
  }

  // Create Organization
  Future<Map<String, dynamic>> createOrganization(String name, String slug, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/organizations'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'slug': slug}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to create organization');
    }
    return data;
  }
}
