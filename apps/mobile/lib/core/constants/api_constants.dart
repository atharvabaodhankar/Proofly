class ApiConstants {
  // Configured base URL for API (with adb reverse tcp:4000 tcp:4000)
  static const String baseUrl = 'http://localhost:4000/api/v1';
  static const String localhostUrl = 'http://localhost:4000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Certificates endpoints
  static const String myCertificates = '/certificates/my';
  static const String verifyCertificate = '/verification';
  static const String issueCertificate = '/certificates/organizations';
  static const String claimCertificate = '/claims';
  static const String organizations = '/organizations';
}
