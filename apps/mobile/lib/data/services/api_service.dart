import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/certificate_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  String baseUrl = ApiConstants.localhostUrl;

  ApiService({String? customUrl}) {
    if (customUrl != null) baseUrl = customUrl;
  }

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl${ApiConstants.login}'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (_) {
      // Mock fallback for offline preview
      return {
        'token': 'mock_jwt_token',
        'user': {
          'id': 'mock-user-1',
          'name': 'Alex Rivera',
          'email': email,
          'role': 'recipient',
        },
      };
    }
  }

  // Auth: Register
  Future<Map<String, dynamic>> register(
      String email, String password, String name, String role) async {
    try {
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
      return jsonDecode(res.body);
    } catch (_) {
      return {
        'token': 'mock_jwt_token',
        'user': {
          'id': 'mock-user-1',
          'name': name,
          'email': email,
          'role': role,
        },
      };
    }
  }

  // Get My Certificates
  Future<List<CertificateModel>> getMyCertificates(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl${ApiConstants.myCertificates}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['certificates'] as List? ?? [];
        return list.map((c) => CertificateModel.fromJson(c)).toList();
      }
    } catch (_) {}

    // High quality mock certificates from mock.html
    return [
      CertificateModel(
        id: '1',
        certificateNumber: 'CERT-2026-BC01',
        organizationId: 'org-1',
        organizationName: 'Global Tech University',
        recipientName: 'Alex Chen',
        recipientEmail: 'alex@techinst.edu',
        title: 'Advanced Cloud Architecture',
        description: 'Mastery of distributed systems, cloud computing, and microservices on AWS.',
        issueDate: '2026-10-24',
        expiryDate: '2029-10-24',
        s3ObjectKey: 'certs/1.pdf',
        documentHash: '0x8f2a9b3e7c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c3c91a0',
        status: 'CLAIMED',
        txHash: '0x8f2a9b3e7c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c3c91',
        blockNumber: 45919403,
      ),
      CertificateModel(
        id: '2',
        certificateNumber: 'CERT-2026-DS02',
        organizationId: 'org-1',
        organizationName: 'Tech Institute of Innovation',
        recipientName: 'Alex Chen',
        recipientEmail: 'alex@techinst.edu',
        title: 'Certified Data Scientist (CDS)',
        description: 'Comprehensive study of predictive modeling, neural networks, and statistical inference.',
        issueDate: '2026-08-26',
        s3ObjectKey: 'certs/2.pdf',
        documentHash: '0x5184c55260147ba3f714268c33a294f61491812253fed370bcd347241930270c',
        status: 'ISSUED',
        txHash: '0x8ef51e3c178490eb23906c9f3f7c6509f8e2ca8a311e8ebe25321ddaa31c58ed',
        blockNumber: 45919403,
      ),
    ];
  }

  // Verify Certificate by query
  Future<Map<String, dynamic>> verifyCertificate(String query) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl${ApiConstants.verifyCertificate}/$query'),
        headers: _headers(),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {
        'status': 'VALID',
        'certificate': {
          'certificate_number': query,
          'title': 'Certified Data Scientist (CDS)',
          'recipient_name': 'Alexei Vronsky',
          'issue_date': '2026-10-24',
          'expiry_date': '2029-10-24',
          'document_hash': '0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          'organizations': {'name': 'Global Tech Institute'},
          'tx_hash': '0x8f2a9b3e7c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c3c91',
        },
        'verification': {
          'isValid': true,
          'isRevoked': false,
          'network': 'Polygon Amoy (80002)',
        },
      };
    }
  }

  // Issue Certificate
  Future<Map<String, dynamic>> issueCertificate(
      String orgId, Map<String, dynamic> payload, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/certificates/organizations/$orgId/certificates'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    return jsonDecode(res.body);
  }
}
