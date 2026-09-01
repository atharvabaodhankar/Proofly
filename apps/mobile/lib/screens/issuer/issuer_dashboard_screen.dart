import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/certificate_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'issue_certificate_screen.dart';
import '../certificates/certificate_detail_screen.dart';

class IssuerDashboardScreen extends StatefulWidget {
  const IssuerDashboardScreen({super.key});

  @override
  State<IssuerDashboardScreen> createState() => _IssuerDashboardScreenState();
}

class _IssuerDashboardScreenState extends State<IssuerDashboardScreen> {
  final ApiService _api = ApiService();
  List<CertificateModel> _issuedCerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIssuedCertificates();
  }

  void _fetchIssuedCertificates() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null || auth.activeOrg == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final certs = await _api.getOrgCertificates(auth.activeOrg!.id, auth.token!);
      setState(() {
        _issuedCerts = certs;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final org = auth.activeOrg;

    final totalIssued = _issuedCerts.length;
    final pendingCount = _issuedCerts.where((c) => c.status == 'QUEUED' || c.status == 'SUBMITTED').length;
    final revokedCount = _issuedCerts.where((c) => c.status == 'REVOKED').length;

    return Scaffold(
      floatingActionButton: org != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Issue Certificate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IssueCertificateScreen()),
                );
                if (created == true) {
                  _fetchIssuedCertificates();
                }
              },
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _fetchIssuedCertificates(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                org?.name ?? 'Institution Dashboard',
                style: AppTypography.headlineMd(isDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Polygon Amoy anchoring & institutional management.',
                style: AppTypography.bodyMd(isDark),
              ),
              const SizedBox(height: 20),

              if (org == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text('No Active Organization', style: AppTypography.headlineSm(isDark)),
                      const SizedBox(height: 6),
                      Text(
                        'Your account is currently registered as a recipient. Sign in with an issuer account to issue credentials.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd(isDark),
                      ),
                    ],
                  ),
                )
              else ...[
                // Top Stats Grid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL CREDENTIALS ISSUED',
                        style: AppTypography.labelSm(true).copyWith(color: Colors.white70, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalIssued',
                            style: AppTypography.display(true).copyWith(color: Colors.white, fontSize: 38),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Polygon Amoy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Pending & Revoked Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'PENDING ANCHOR',
                        value: '$pendingCount',
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.secondary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatCard(
                        title: 'REVOKED',
                        value: '$revokedCount',
                        icon: Icons.block_rounded,
                        iconColor: AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Issued Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Issued Certificates', style: AppTypography.headlineSm(isDark)),
                    Text('${_issuedCerts.length} total', style: AppTypography.labelSm(isDark)),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                  )
                else if (_issuedCerts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.post_add_rounded, size: 48, color: AppColors.outlineLight),
                          const SizedBox(height: 12),
                          Text('No certificates issued yet', style: AppTypography.headlineSm(isDark)),
                          const SizedBox(height: 6),
                          Text('Tap "Issue Certificate" below to issue your first on-chain credential.', textAlign: TextAlign.center, style: AppTypography.bodyMd(isDark)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _issuedCerts.length,
                    itemBuilder: (context, index) {
                      final cert = _issuedCerts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CertificateDetailScreen(certificate: cert)),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cert.recipientName,
                                        style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      Text(cert.title, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.verifiedGreenBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    cert.status,
                                    style: const TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headlineLg(isDark).copyWith(fontSize: 24)),
        ],
      ),
    );
  }
}
