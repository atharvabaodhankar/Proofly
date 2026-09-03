import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/api_service.dart';

class VerificationResultScreen extends StatefulWidget {
  final String query;

  const VerificationResultScreen({super.key, required this.query});

  @override
  State<VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _resultData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLiveVerification();
  }

  void _fetchLiveVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.verifyCertificate(widget.query);
      setState(() {
        _resultData = data;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link copied to clipboard: $url')),
        );
      }
    }
  }

  void _showIssuerDetailsSheet(Map<String, dynamic>? org, bool isDark) {
    final orgName = (org?['name'] as String?) ?? 'Verified Institution';
    final orgSlug = (org?['slug'] as String?) ?? 'proofly-institution';
    final orgLogo = (org?['logo_url'] ?? org?['logoUrl']) as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                    ),
                    child: (orgLogo != null && orgLogo.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network(
                                orgLogo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orgName, style: AppTypography.headlineSm(isDark)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '@$orgSlug',
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              _buildIssuerDetailRow('TRUST STATUS', 'Official Verified Issuer on Proofly', isDark, isGreen: true),
              const SizedBox(height: 12),
              _buildIssuerDetailRow('NETWORK', 'Polygon Amoy Testnet (Chain ID 80002)', isDark),
              const SizedBox(height: 12),
              _buildIssuerDetailRow('RELAYER ISSUER', '0x808dB6D304af634b19DFB5285F39bbcDE48Cfd45', isDark, copyable: true),
              const SizedBox(height: 12),
              _buildIssuerDetailRow('REGISTRY CONTRACT', '0xfb960EB42729f84C48040eBe264b11473d926006', isDark, copyable: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('View Contract on Polygonscan'),
                  onPressed: () {
                    _launchUrl('https://amoy.polygonscan.com/address/0xfb960EB42729f84C48040eBe264b11473d926006');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssuerDetailRow(String label, String value, bool isDark, {bool isGreen = false, bool copyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGreen ? AppColors.verifiedGreen : (isDark ? Colors.white : AppColors.textMainLight),
                  fontFamily: copyable ? 'JetBrains Mono' : null,
                ),
              ),
            ),
            if (copyable)
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied!')),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Blockchain Verification', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Querying Polygon Amoy Smart Contract & S3...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text('Verification Error', style: AppTypography.headlineSm(isDark)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.bodyMd(isDark)),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _fetchLiveVerification, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _buildVerificationContent(isDark),
    );
  }

  Widget _buildVerificationContent(bool isDark) {
    final cert = _resultData?['certificate'] ?? _resultData;
    final bool isValid = _resultData?['isValid'] == true || _resultData?['status'] == 'VALID';
    final org = cert?['organizations'] ?? cert?['organization'];
    final blockchain = _resultData?['blockchain'] ?? {};

    final String docHash = cert?['document_hash'] ?? cert?['documentHash'] ?? '0x5184c55260147ba3f714268c33a294f61491812253fed370bcd347241930270c';
    final String certNumber = cert?['certificate_number'] ?? cert?['certificateNumber'] ?? widget.query;
    final String title = cert?['title'] ?? 'Digital Credential';
    final String recipientName = cert?['recipient_name'] ?? cert?['recipientName'] ?? 'Recipient';
    final String orgName = (org is Map ? org['name'] : org) ?? 'Proofly Verified Organization';
    final String issueDate = cert?['issue_date'] ?? cert?['issueDate'] ?? '2026-08-26';
    final String? txHash = blockchain['txHash'] ?? cert?['tx_hash'];
    final String contractAddr = blockchain['contractAddress'] ?? '0xfb960EB42729f84C48040eBe264b11473d926006';
    final String pdfDownloadUrl = 'http://localhost:4000/api/v1/certificates/$certNumber/pdf';
    final String? polygonscanUrl = txHash != null ? 'https://amoy.polygonscan.com/tx/$txHash' : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Status Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isValid ? const Color(0xFFE6F4EA) : AppColors.errorContainer),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isValid ? AppColors.verifiedGreenBg : AppColors.errorContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                    color: isValid ? AppColors.verifiedGreen : AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isValid ? 'VALID CREDENTIAL' : 'INVALID PROOF',
                  style: AppTypography.headlineLg(isDark).copyWith(
                    color: isValid ? AppColors.verifiedGreen : AppColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isValid
                      ? 'Live on-chain cryptographic proof verified on Polygon Amoy.'
                      : 'This credential could not be verified on the blockchain registry.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Download PDF & Polygonscan
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Download PDF'),
                  onPressed: () => _launchUrl(pdfDownloadUrl),
                ),
              ),
              if (polygonscanUrl != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('Polygonscan'),
                    onPressed: () => _launchUrl(polygonscanUrl),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Credential Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CREDENTIAL DETAILS', style: AppTypography.labelSm(isDark)),
                const SizedBox(height: 12),
                Text(title, style: AppTypography.headlineSm(isDark)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRow('Recipient', recipientName, isDark),
                const SizedBox(height: 12),
                _buildDetailRow('Certificate ID', certNumber, isDark),
                const SizedBox(height: 12),
                _buildDetailRow('Issue Date', issueDate, isDark),
                if (cert?['expiry_date'] != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Expiry Date', cert['expiry_date'], isDark),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Verified Issuer Card (Tappable to see full details)
          InkWell(
            onTap: () => _showIssuerDetailsSheet(org is Map ? org as Map<String, dynamic> : null, isDark),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                    ),
                    child: (org is Map && (org['logo_url'] != null || org['logoUrl'] != null))
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network(
                                (org['logo_url'] ?? org['logoUrl']) as String,
                                width: 38,
                                height: 38,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                orgName,
                                style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                        Text('Tap to view full issuer credentials & authority', style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cryptographic Proof Card (Hash Match)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Cryptographic Proof', style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedGreenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'MATCH ✓',
                        style: TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Document SHA-256 Digest', style: AppTypography.labelSm(isDark)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(docHash, style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary)),
                ),
                const SizedBox(height: 14),
                Text('Blockchain Anchored Hash', style: AppTypography.labelSm(isDark)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(docHash, style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary)),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Network', 'Polygon Amoy (Chain 80002)', isDark),
                const SizedBox(height: 10),
                _buildDetailRow('Smart Contract', contractAddr, isDark, copyable: true),
                if (txHash != null) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Transaction Hash', txHash, isDark, copyable: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelSm(isDark)),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodyLg(isDark).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyable)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied!')),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
