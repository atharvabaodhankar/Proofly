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
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          initials,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isIssuer ? AppColors.primary.withValues(alpha: 0.15) : AppColors.verifiedGreenBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isIssuer ? 'ORGANIZATION ADMIN' : 'RECIPIENT LEARNER',
                                style: TextStyle(
                                  color: isIssuer ? AppColors.primary : AppColors.verifiedGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _showEditProfileDialog(context, authProvider, isDark),
                      ),
                    ],
                  ),

                  if (isIssuer && activeOrg != null) ...[
                    const SizedBox(height: 20),
                    Text('ACTIVE ISSUING ORGANIZATION', style: AppTypography.labelSm(isDark).copyWith(fontSize: 10)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: (activeOrg.logoUrl != null && activeOrg.logoUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(activeOrg.logoUrl!, fit: BoxFit.contain),
                                  )
                                : Center(
                                    child: Text(
                                      activeOrg.name.isNotEmpty ? activeOrg.name[0].toUpperCase() : 'O',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeOrg.name,
                                  style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '@${activeOrg.slug}',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_rounded, color: AppColors.verifiedGreen, size: 20),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences
            Text('PREFERENCES', style: AppTypography.labelSm(isDark)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                    title: Text('Dark Mode', style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14)),
                    subtitle: Text(themeProvider.isDarkMode ? 'Dark luxury theme active' : 'Clean light theme active', style: const TextStyle(fontSize: 12)),
                    value: themeProvider.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security & Blockchain
            Text('BLOCKCHAIN & NETWORK', style: AppTypography.labelSm(isDark)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.hub_rounded, color: AppColors.secondary),
                    title: Text('Network Status', style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14)),
                    subtitle: const Text('Polygon Amoy (Chain 80002)', style: TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedGreenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ONLINE ✓', style: TextStyle(color: AppColors.verifiedGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code_rounded, color: AppColors.secondary),
                    title: Text('Registry Contract', style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14)),
                    subtitle: const Text('0xfb96...6006', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: '0xfb960EB42729f84C48040eBe264b11473d926006'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Smart Contract address copied!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          onPressed: () {
                            _launchUrl('https://amoy.polygonscan.com/address/0xfb960EB42729f84C48040eBe264b11473d926006');
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondary),
                    title: Text('Relayer Issuer Address', style: AppTypography.bodyLg(isDark).copyWith(fontSize: 14)),
                    subtitle: const Text('0x808d...fd45', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: '0x808dB6D304af634b19DFB5285F39bbcDE48Cfd45'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Relayer address copied!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () => _showLogoutDialog(context, authProvider, isDark),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
