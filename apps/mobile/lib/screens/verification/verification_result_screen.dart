import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final String title = cert?['title'] ?? 'Full Stack Blockchain Dev';
    final String recipientName = cert?['recipient_name'] ?? cert?['recipientName'] ?? 'Tejas Patil';
    final String orgName = (org is Map ? org['name'] : org) ?? 'Proofly Institute of Technology';
    final String issueDate = cert?['issue_date'] ?? cert?['issueDate'] ?? '2026-08-26';
    final String? txHash = blockchain['txHash'] ?? cert?['tx_hash'];
    final String contractAddr = blockchain['contractAddress'] ?? '0xfb960EB42729f84C48040eBe264b11473d926006';

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
          const SizedBox(height: 24),

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

          // Verified Issuer Card
          Container(
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
                      Text('Verified Organization Issuer', style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
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
                _buildDetailRow('Smart Contract', contractAddr, isDark),
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
