import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/certificates_provider.dart';
import '../verification/qr_scanner_screen.dart';

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
        const SnackBar(content: Text('Please enter your 64-character claim token.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first to link this credential.')),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isClaimed
                        ? AppColors.verifiedGreen.withValues(alpha: 0.15)
                        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLowLight),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isClaimed ? AppColors.verifiedGreen : AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isClaimed ? Icons.check_circle_rounded : Icons.vpn_key_rounded,
                    color: _isClaimed ? AppColors.verifiedGreen : AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  _isClaimed ? 'Credential Claimed!' : 'Enter Your Claim Token',
                  style: AppTypography.headlineMd(isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isClaimed
                      ? 'This certificate has been cryptographically linked to your personal wallet.'
                      : 'Paste the invitation token from your email or scan the QR code to permanently add the credential to your account.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(isDark),
                ),
                const SizedBox(height: 32),

                if (_isClaimed) ...[
                  // Success Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.verifiedGreen.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verifiedGreen.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.school_rounded, color: AppColors.primary, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          _claimedTitle ?? 'Verifiable Certificate',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMd(isDark).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _claimedOrg ?? 'Proofly Organization',
                          style: AppTypography.labelSm(isDark).copyWith(color: AppColors.cyanAccent),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppColors.verifiedGreen, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Anchored on Polygon Amoy (80002)',
                              style: TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('View in My Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ] else ...[
                  // Token Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Claim Token', style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              icon: const Icon(Icons.paste_rounded, size: 16),
                              label: const Text('Paste'),
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  setState(() => _tokenController.text = data!.text!.trim());
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tokenController,
                          maxLines: 2,
                          style: AppTypography.hashMono(color: isDark ? AppColors.cyanAccent : AppColors.primary),
                          decoration: InputDecoration(
                            hintText: 'Paste 64-character token from your email...',
                            hintStyle: TextStyle(color: isDark ? AppColors.outlineDark : AppColors.outlineLight, fontSize: 13),
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // QR Scanner Option
                        OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: const Text('Scan Claim QR Code'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final scanned = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                            );
                            if (scanned != null && scanned.isNotEmpty) {
                              final token = scanned.contains('/claim/') ? scanned.split('/claim/').last : scanned;
                              setState(() => _tokenController.text = token.trim());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Claim Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyAndClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Claim & Link Credential',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Confetti Celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [AppColors.primary, AppColors.cyanAccent, AppColors.emerald, Colors.amber],
            ),
          ),
        ],
      ),
    );
  }
}
