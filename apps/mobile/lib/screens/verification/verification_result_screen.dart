import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class VerificationResultScreen extends StatelessWidget {
  final String query;

  const VerificationResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mockHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verification Result', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                border: Border.all(color: const Color(0xFFE6F4EA)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.verifiedGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.verifiedGreen, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VALID',
                    style: AppTypography.headlineLg(isDark).copyWith(
                      color: AppColors.verifiedGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This credential has been mathematically verified on Polygon Amoy.',
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
                  Text('Certified Data Scientist (CDS)', style: AppTypography.headlineSm(isDark)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildDetailRow('Issued To', 'Alexei Vronsky', isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow('Issue Date', '2026-08-26', isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow('Expiration', '2029-08-26', isDark),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Global Tech Institute',
                              style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                        Text('Verified Issuer Identity', style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
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
                    child: Text(mockHash, style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary)),
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
                    child: Text(mockHash, style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary)),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Network', 'Polygon Amoy (Chain 80002)', isDark),
                  const SizedBox(height: 10),
                  _buildDetailRow('Smart Contract', '0xfb960EB42729f84C48040eBe264b11473d926006', isDark),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelSm(isDark)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyLg(isDark).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
