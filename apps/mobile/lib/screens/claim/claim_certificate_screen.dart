import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/certificates_provider.dart';
import '../main_shell.dart';

class ClaimCertificateScreen extends StatefulWidget {
  final String? initialClaimToken;

  const ClaimCertificateScreen({super.key, this.initialClaimToken});

  @override
  State<ClaimCertificateScreen> createState() => _ClaimCertificateScreenState();
}

class _ClaimCertificateScreenState extends State<ClaimCertificateScreen> {
  final ApiService _api = ApiService();
  late final TextEditingController _tokenController;
  late ConfettiController _confettiController;
  bool _isClaimed = false;
  bool _isLoading = false;
  String? _claimedTitle;
  String? _claimedOrg;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialClaimToken ?? '');
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _verifyAndClaim() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your claim token.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first to claim this credential.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _api.claimCertificate(token, auth.token!);
      final cert = res['certificate'] ?? {};

      setState(() {
        _isLoading = false;
        _isClaimed = true;
        _claimedTitle = cert['title'] ?? 'Verifiable Credential';
        _claimedOrg = cert['organizations']?['name'] ?? 'Proofly Organization';
      });

      _confettiController.play();

      if (mounted) {
        Provider.of<CertificatesProvider>(context, listen: false).loadCertificates(auth.token!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
                        color: (_isClaimed ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.12),
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
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _claimedTitle ?? 'Verifiable Blockchain Certificate',
                              textAlign: TextAlign.center,
                              style: AppTypography.headlineMd(isDark).copyWith(fontSize: 17),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _claimedOrg ?? 'Issued via Polygon Amoy Smart Contract',
                              style: AppTypography.labelSm(isDark),
                            ),
                          ],
                        ),
                      ),
                      if (!_isClaimed)
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
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
                                        color: Colors.black.withValues(alpha: 0.08),
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
                                  'Claim token verification required',
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
                    'Enter your Claim Token',
                    style: AppTypography.headlineLg(isDark).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the claim token sent to your email to link this blockchain credential permanently to your wallet.',
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
                            Text('Claim Secret Token', style: AppTypography.bodyLg(isDark)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 7f8a9b0c-1d2e-3f4a-5b6c-7d8e9f0a1b2c',
                            prefixIcon: Icon(Icons.vpn_key_rounded),
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
                                      Text('Claim on Polygon Amoy'),
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
                  Text('Claimed Successfully!', style: AppTypography.headlineLg(isDark)),
                  const SizedBox(height: 8),
                  Text(
                    'Your credential is now permanently anchored to your account and verifiable on Polygon Amoy.',
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
