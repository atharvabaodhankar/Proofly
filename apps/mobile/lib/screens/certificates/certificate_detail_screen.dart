import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/pdf_downloader.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/certificate_model.dart';

class CertificateDetailScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateDetailScreen({super.key, required this.certificate});

  @override
  State<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  bool _isQrExpanded = false;
  bool _isBlockchainExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cert = widget.certificate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Certificate Detail', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Certificate Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cert.organizationName?.toUpperCase() ?? 'PROOF OF ACHIEVEMENT',
                          style: AppTypography.labelSm(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: AppColors.verifiedGreen),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'THIS IS TO CERTIFY THAT',
                    style: AppTypography.labelSm(isDark).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cert.recipientName,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLg(isDark).copyWith(
                      color: isDark ? AppColors.cyanAccent : AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cert.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMd(isDark).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cert.description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(isDark).copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ISSUE DATE', style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
                          Text(cert.issueDate, style: AppTypography.bodyLg(isDark).copyWith(fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('CERTIFICATE ID', style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
                          Text(cert.certificateNumber, style: AppTypography.bodyLg(isDark).copyWith(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Download PDF'),
                    onPressed: () {
                      PdfDownloader.downloadAndOpenPdf(
                        context: context,
                        url: '${ApiConstants.baseUrl}/certificates/${cert.certificateNumber}/pdf',
                        certificateNumber: cert.certificateNumber,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share Credential'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${ApiConstants.webAppUrl}/verify/${cert.certificateNumber}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification URL copied to clipboard!')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Collapsible QR Code Card
            _buildCollapsibleCard(
              isDark: isDark,
              title: 'Verification QR Code',
              icon: Icons.qr_code_2_rounded,
              iconColor: AppColors.primary,
              isExpanded: _isQrExpanded,
              onToggle: () => setState(() => _isQrExpanded = !_isQrExpanded),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: QrImageView(
                      data: '${ApiConstants.webAppUrl}/verify/${cert.certificateNumber}',
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan with any mobile camera to verify on Polygon Amoy live.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(isDark).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Collapsible Blockchain Proof Card
            _buildCollapsibleCard(
              isDark: isDark,
              title: 'Blockchain Proof',
              icon: Icons.link_rounded,
              iconColor: AppColors.secondary,
              isExpanded: _isBlockchainExpanded,
              onToggle: () => setState(() => _isBlockchainExpanded = !_isBlockchainExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProofRow('Network', 'Polygon Amoy (Chain 80002)', isDark),
                  const SizedBox(height: 12),
                  _buildProofRow('Document SHA-256', cert.documentHash, isDark, copyable: true),
                  const SizedBox(height: 12),
                  _buildProofRow('Transaction Hash', cert.txHash ?? 'Pending in mempool', isDark, copyable: cert.txHash != null),
                  if (cert.blockNumber != null) ...[
                    const SizedBox(height: 12),
                    _buildProofRow('Block Number', '#${cert.blockNumber}', isDark),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(title, style: AppTypography.bodyLg(isDark)),
                      ],
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
                    ),
                  ],
                ),
                if (isExpanded) child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProofRow(String label, String value, bool isDark, {bool copyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary),
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
                      SnackBar(content: Text('$label copied to clipboard!')),
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
