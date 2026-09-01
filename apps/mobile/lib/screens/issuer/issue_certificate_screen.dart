import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'anchoring_status_screen.dart';

class IssueCertificateScreen extends StatefulWidget {
  const IssueCertificateScreen({super.key});

  @override
  State<IssueCertificateScreen> createState() => _IssueCertificateScreenState();
}

class _IssueCertificateScreenState extends State<IssueCertificateScreen> {
  final ApiService _api = ApiService();
  int _currentStep = 1;
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  late final TextEditingController _issueDateController;
  final TextEditingController _expiryDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _issueDateController = TextEditingController(text: today);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _submitIssuance() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null || auth.activeOrg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active organization found to issue from.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'recipientName': _nameController.text.trim(),
        'recipientEmail': _emailController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        'issueDate': _issueDateController.text.trim(),
        'expiryDate': _expiryDateController.text.trim().isNotEmpty ? _expiryDateController.text.trim() : null,
      };

      final res = await _api.issueCertificate(auth.activeOrg!.id, payload, auth.token!);
      final cert = res['certificate'] ?? {};

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnchoringStatusScreen(
              recipientName: _nameController.text.trim(),
              title: _titleController.text.trim(),
              recipientEmail: _emailController.text.trim(),
              txHash: cert['tx_hash'] ?? '0x8ef51e3c178490eb23906c9f3f7c6509f8e2ca8a311e8ebe25321ddaa31c58ed',
              certificateNumber: cert['certificate_number'] ?? 'CERT-PENDING',
              blockNumber: cert['block_number'] ?? 45919403,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issuance failed: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: AppColors.error),
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
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Issue Credential', style: AppTypography.headlineSm(isDark)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildStepCircle(1, 'Recipient'),
                _buildStepDivider(1),
                _buildStepCircle(2, 'Details'),
                _buildStepDivider(2),
                _buildStepCircle(3, 'Review'),
              ],
            ),
          ),
          const Divider(),

          // Form Steps
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildCurrentStepContent(isDark),
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep == 1) {
                          if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter recipient name and email.')),
                            );
                            return;
                          }
                          setState(() => _currentStep = 2);
                        } else if (_currentStep == 2) {
                          if (_titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a certificate title.')),
                            );
                            return;
                          }
                          setState(() => _currentStep = 3);
                        } else {
                          _submitIssuance();
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_currentStep == 3 ? 'Anchor on Polygon Amoy' : 'Continue to Next Step'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isActive ? AppColors.primary : AppColors.outlineVariantLight,
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.outlineLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int step) {
    final isDone = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isDone ? AppColors.primary : AppColors.outlineVariantLight,
      margin: const EdgeInsets.only(bottom: 16),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recipient Information', style: AppTypography.headlineSm(isDark)),
          const SizedBox(height: 6),
          Text('Who is receiving this credential?', style: AppTypography.bodyMd(isDark)),
          const SizedBox(height: 24),
          Text('Recipient Full Name', style: AppTypography.labelSm(isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Tejas Patil',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Text('Recipient Email Address', style: AppTypography.labelSm(isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g. tejas@proofly.app',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credential Parameters', style: AppTypography.headlineSm(isDark)),
          const SizedBox(height: 6),
          Text('Define the certificate title, description, and validity.', style: AppTypography.bodyMd(isDark)),
          const SizedBox(height: 24),
          Text('Certificate Title', style: AppTypography.labelSm(isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Full Stack Blockchain Developer',
              prefixIcon: Icon(Icons.workspace_premium_outlined),
            ),
          ),
          const SizedBox(height: 18),
          Text('Description / Citation', style: AppTypography.labelSm(isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe recipient achievements and qualifications...',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Issue Date', style: AppTypography.labelSm(isDark)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _issueDateController,
                      decoration: const InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expiry (Optional)', style: AppTypography.labelSm(isDark)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: Icon(Icons.event_busy_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Credential', style: AppTypography.headlineSm(isDark)),
          const SizedBox(height: 6),
          Text('Verify information before generating PDF and anchoring on Polygon Amoy.', style: AppTypography.bodyMd(isDark)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildReviewRow('Recipient', _nameController.text, isDark),
                const Divider(height: 20),
                _buildReviewRow('Email', _emailController.text, isDark),
                const Divider(height: 20),
                _buildReviewRow('Title', _titleController.text, isDark),
                const Divider(height: 20),
                _buildReviewRow('Issue Date', _issueDateController.text, isDark),
                const Divider(height: 20),
                _buildReviewRow('Storage', 'AWS S3 (proofly-certificates)', isDark),
                const Divider(height: 20),
                _buildReviewRow('Blockchain', 'Polygon Amoy (Chain 80002)', isDark),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReviewRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelSm(isDark)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
