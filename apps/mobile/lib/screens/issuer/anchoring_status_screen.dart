import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../main_shell.dart';

class AnchoringStatusScreen extends StatefulWidget {
  final String recipientName;
  final String title;
  final String recipientEmail;

  const AnchoringStatusScreen({
    super.key,
    required this.recipientName,
    required this.title,
    required this.recipientEmail,
  });

  @override
  State<AnchoringStatusScreen> createState() => _AnchoringStatusScreenState();
}

class _AnchoringStatusScreenState extends State<AnchoringStatusScreen> {
  int _currentProgressStep = 1;
  final String _mockTxHash = '0x8ef51e3c178490eb23906c9f3f7c6509f8e2ca8a311e8ebe25321ddaa31c58ed';

  @override
  void initState() {
    super.initState();
    _simulateAnchoring();
  }

  void _simulateAnchoring() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _currentProgressStep = 2);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _currentProgressStep = 3);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _currentProgressStep = 4);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          },
        ),
        title: Text('Anchoring Status', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentProgressStep == 4 ? Icons.verified_rounded : Icons.enhanced_encryption_rounded,
                      color: _currentProgressStep == 4 ? AppColors.verifiedGreen : AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentProgressStep == 4 ? 'Secured on Blockchain' : 'Securing Credential',
                    style: AppTypography.headlineMd(isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Anchoring cryptographic proof to Polygon Amoy.',
                    style: AppTypography.bodyMd(isDark),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NETWORK', style: AppTypography.labelSm(isDark)),
                      const Text('Polygon Amoy (80002)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stepper Items
            _buildStepItem(
              stepNumber: 1,
              title: 'PDF Generated & SHA-256 Hashed',
              subtitle: 'Uploaded to AWS S3 & cryptographic digest computed.',
              isCompleted: _currentProgressStep >= 1,
              isActive: _currentProgressStep == 1,
              isDark: isDark,
            ),
            _buildStepItem(
              stepNumber: 2,
              title: 'Relayer Gasless Submission',
              subtitle: 'Broadcasting transaction to Polygon Amoy validators.',
              isCompleted: _currentProgressStep >= 2,
              isActive: _currentProgressStep == 2,
              isDark: isDark,
            ),
            _buildStepItem(
              stepNumber: 3,
              title: 'Block Confirmation',
              subtitle: 'Mined in block #45919403 on Polygon Amoy testnet.',
              isCompleted: _currentProgressStep >= 3,
              isActive: _currentProgressStep == 3,
              isDark: isDark,
            ),
            _buildStepItem(
              stepNumber: 4,
              title: 'Credential Proof Finalized',
              subtitle: 'Permanent immutable record active for instant verification.',
              isCompleted: _currentProgressStep >= 4,
              isActive: _currentProgressStep == 4,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Transaction Hash Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TRANSACTION HASH', style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _mockTxHash));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction Hash copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mockTxHash,
                    style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bottom CTA
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCompleted
                ? AppColors.verifiedGreen
                : (isActive ? AppColors.primary : AppColors.outlineVariantLight),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLg(isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? (isDark ? Colors.white : AppColors.textMainLight) : AppColors.outlineLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodyMd(isDark).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
