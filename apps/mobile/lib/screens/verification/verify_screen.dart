import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'verification_result_screen.dart';
import 'qr_scanner_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _verify() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Certificate ID or Document SHA-256 Hash.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
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
            const SizedBox(height: 28),

            // Camera Scanner Primary Card
            InkWell(
              onTap: () async {
                final nav = Navigator.of(context);
                final scanned = await nav.push<String>(
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
                if (!mounted) return;
                if (scanned != null && scanned.isNotEmpty) {
                  final cleanQuery = scanned.contains('/verify/') ? scanned.split('/verify/').last : scanned;
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => VerificationResultScreen(query: cleanQuery),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text('Scan Certificate QR Code', style: AppTypography.headlineMd(isDark).copyWith(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      'Scan dynamic QR on any physical or digital certificate',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSm(isDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Divider with OR
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineLight)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR ENTER MANUALLY', style: AppTypography.labelSm(isDark).copyWith(letterSpacing: 1.5)),
                ),
                Expanded(child: Divider(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineLight)),
              ],
            ),
            const SizedBox(height: 24),

            // Manual Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Certificate ID / Hash', style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Enter Certificate ID (e.g. CERT-20260826-XXXX)',
                      hintStyle: TextStyle(color: isDark ? AppColors.outlineDark : AppColors.outlineLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify On-Chain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
