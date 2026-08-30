import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'issue_certificate_screen.dart';

class IssuerDashboardScreen extends StatelessWidget {
  const IssuerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Issue Certificate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IssueCertificateScreen()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Issuer Dashboard', style: AppTypography.headlineMd(isDark)),
            const SizedBox(height: 4),
            Text(
              'Manage institutional issuance & Polygon Amoy anchoring.',
              style: AppTypography.bodyMd(isDark),
            ),
            const SizedBox(height: 20),

            // Top Stats Grid
            // Total Issued Card (Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL CREDENTIALS ISSUED',
                    style: AppTypography.labelSm(true).copyWith(color: Colors.white70, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1,240',
                        style: AppTypography.display(true).copyWith(color: Colors.white, fontSize: 38),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('+18% this mo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Pending & Revoked Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'PENDING ANCHOR',
                    value: '12',
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.secondary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'REVOKED',
                    value: '3',
                    icon: Icons.block_rounded,
                    iconColor: AppColors.error,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: AppTypography.headlineSm(isDark)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildActivityItem('Sarah Jenkins', 'UX Foundations Cert', '2m ago', isDark),
            _buildActivityItem('Michael Chen', 'Advanced React & Blockchain', '1h ago', isDark),
            _buildActivityItem('Elena Rodriguez', 'Cybersecurity Analyst', '3h ago', isDark),
            _buildActivityItem('David Kim', 'Full Stack Development', '1d ago', isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headlineLg(isDark).copyWith(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String name, String certTitle, String time, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(certTitle, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
                ],
              ),
            ),
            Text(time, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
