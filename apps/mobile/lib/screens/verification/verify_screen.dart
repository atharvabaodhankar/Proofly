import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'verification_result_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _queryController = TextEditingController(text: 'CERT-20260826-436B4A');
  bool _isLoading = false;

  void _verify() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationResultScreen(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Instant Verification', style: AppTypography.headlineLg(isDark)),
            const SizedBox(height: 8),
            Text(
              'Verify any credential against Polygon Amoy smart contracts without connecting a wallet.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(isDark),
            ),
            const SizedBox(height: 32),

            // Scanner Simulation Card
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('Scan QR Code from Certificate', style: AppTypography.bodyLg(isDark)),
                  const SizedBox(height: 6),
                  Text('Point your camera at the QR code', style: AppTypography.labelSm(isDark)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR SEARCH MANUALLY', style: AppTypography.labelSm(isDark)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Search by Certificate ID / Hash
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                hintText: 'Enter Certificate ID (e.g. CERT-...)',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Verify On-Chain'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
