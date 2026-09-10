class ApiConstants {
  // Configured base URL for API (defaults to live production, can be overridden with --dart-define=API_URL=https://...)
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://proofly-api.vercel.app/api/v1');
  static String get webAppUrl => baseUrl.replaceAll('/api/v1', '');

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Certificates endpoints
  static const String myCertificates = '/certificates/my';
  static const String verifyCertificate = '/verify';
  static const String issueCertificate = '/certificates/organizations';
  static const String claimCertificate = '/claims';
  static const String organizations = '/organizations';
}
