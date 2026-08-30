import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../main_shell.dart';

class ClaimCertificateScreen extends StatefulWidget {
  final String? claimToken;

  const ClaimCertificateScreen({super.key, this.claimToken});

  @override
  State<ClaimCertificateScreen> createState() => _ClaimCertificateScreenState();
}

class _ClaimCertificateScreenState extends State<ClaimCertificateScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'alex.chen@gmail.com');
  late ConfettiController _confettiController;
  bool _isClaimed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _verifyAndClaim() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
      _isClaimed = true;
    });

    _confettiController.play();
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
        title: Text('Claim Credential', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Locked / Unlocked Preview Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isClaimed ? AppColors.emerald : (isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isClaimed ? AppColors.emerald : AppColors.primary).withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Certified Cloud Solutions Architect',
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineMd(isDark).copyWith(fontSize: 17),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Global Tech University',
                              style: AppTypography.labelSm(isDark),
                            ),
                          ],
                        ),
                      ),
                      if (!_isClaimed)
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withOpacity(0.75),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Locked Credential',
                                  style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Email verification required',
                                  style: AppTypography.labelSm(isDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (!_isClaimed) ...[
                  Text(
                    'Claim your certificate',
                    style: AppTypography.headlineLg(isDark).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the recipient email address to verify identity and unlock your blockchain proof.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(isDark),
                  ),
                  const SizedBox(height: 28),

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
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary,
                              child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Text('Recipient Identity Verification', style: AppTypography.bodyLg(isDark)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'jane@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyAndClaim,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Verify & Unlock Credential'),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Success State
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.verifiedGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.verifiedGreen, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text('Verified Successfully!', style: AppTypography.headlineLg(isDark)),
                  const SizedBox(height: 8),
                  Text(
                    'Your credential is now permanently linked to your wallet identity and verifiable on Polygon Amoy.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(isDark),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet_rounded),
                      label: const Text('Go to My Credentials'),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.emerald,
                AppColors.cyanAccent,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
