import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthProvider auth, bool isDark) {
    final nameController = TextEditingController(text: auth.user?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Full Name', style: AppTypography.headlineSm(isDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update your display name across issued credentials.', style: AppTypography.bodyMd(isDark).copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                if (auth.user != null) {
                  auth.setUser(auth.user!.copyWith(name: newName));
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile name updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to log out of Proofly? Your local credential tokens will be safely cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final activeOrg = authProvider.activeOrg;
    final bool isIssuer = user?.role == 'org_admin' || user?.role == 'org_issuer';

    final String initials = user?.name.isNotEmpty == true
        ? user!.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'U';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Profile Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.cyanAccent, AppColors.primary],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: isDark ? AppColors.cyanAccent : AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'User Profile', style: AppTypography.headlineSm(isDark)),
                            const SizedBox(height: 2),
                            Text(user?.email ?? 'No email linked', style: AppTypography.bodyMd(isDark).copyWith(fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isIssuer ? AppColors.primary.withValues(alpha: 0.15) : AppColors.verifiedGreenBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isIssuer ? AppColors.primary.withValues(alpha: 0.3) : AppColors.verifiedGreen.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isIssuer ? 'ORGANIZATION ADMIN' : 'RECIPIENT LEARNER',
                                style: TextStyle(
                                  color: isIssuer ? AppColors.primary : AppColors.verifiedGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditProfileDialog(context, authProvider, isDark),
                      ),
                    ],
                  ),

                  if (isIssuer && activeOrg != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('ACTIVE ISSUING INSTITUTION', style: AppTypography.labelSm(isDark).copyWith(fontSize: 10, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: const Center(
                              child: Text('🏢', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeOrg.name,
                                  style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '@${activeOrg.slug}',
                                  style: TextStyle(color: isDark ? AppColors.cyanAccent : AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedGreenBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppColors.verifiedGreen),
                                SizedBox(width: 4),
                                Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme & Preferences Section
            Text('APP PREFERENCES', style: AppTypography.labelSm(isDark).copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: Text('Dark Mode', style: AppTypography.bodyLg(isDark).copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Switch between light and dark themes', style: AppTypography.bodyMd(isDark).copyWith(fontSize: 12)),
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? AppColors.cyanAccent : Colors.amber.shade700,
                ),
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            const SizedBox(height: 24),

            // Blockchain Diagnostics Section
            Text('BLOCKCHAIN DIAGNOSTICS', style: AppTypography.labelSm(isDark).copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDiagnosticRow(
                    context: context,
                    isDark: isDark,
                    label: 'Network',
                    value: 'Polygon Amoy (Chain 80002)',
                    statusColor: AppColors.verifiedGreen,
                  ),
                  const Divider(height: 20),
                  _buildDiagnosticRow(
                    context: context,
                    isDark: isDark,
                    label: 'Smart Contract',
                    value: '0xfb960EB42729f84C48040eBe264b11473d926006',
                    copyable: true,
                    actionButton: IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.cyanAccent),
                      onPressed: () => _launchUrl('https://amoy.polygonscan.com/address/0xfb960EB42729f84C48040eBe264b11473d926006'),
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDiagnosticRow(
                    context: context,
                    isDark: isDark,
                    label: 'Issuer Relayer',
                    value: '0x808d98d286ad5ec173d12d4cfcc66a3d6cb4fd45',
                    copyable: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showLogoutDialog(context, authProvider, isDark),
              ),
            ),
            const SizedBox(height: 16),

            // App Version Footer
            Center(
              child: Text(
                'Proofly Protocol v1.0.0 • Polygon Amoy',
                style: AppTypography.labelSm(isDark).copyWith(fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow({
    required BuildContext context,
    required bool isDark,
    required String label,
    required String value,
    Color? statusColor,
    bool copyable = false,
    Widget? actionButton,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.bodyMd(isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: statusColor ?? (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
        if (actionButton != null) ...[
          const SizedBox(width: 8),
          actionButton,
        ],
      ],
    );
  }
}
