import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final notifications = [
      {
        'title': 'Certificate Claimed',
        'desc': 'Alex Mercer has claimed their Python Certification.',
        'time': '2m ago',
        'icon': Icons.verified_rounded,
        'color': AppColors.verifiedGreen,
        'unread': true,
      },
      {
        'title': 'New Blockchain Issuance',
        'desc': '25 certificates successfully anchored to Polygon Amoy.',
        'time': '1h ago',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.primary,
        'unread': false,
      },
      {
        'title': 'System Security Update',
        'desc': 'Enhanced cryptographic hashing features deployed globally.',
        'time': 'Yesterday',
        'icon': Icons.security_update_good_rounded,
        'color': AppColors.secondary,
        'unread': false,
      },
      {
        'title': 'Expiring Credential Alert',
        'desc': '3 Annual Safety Certifications are expiring in 30 days.',
        'time': '3d ago',
        'icon': Icons.timer_rounded,
        'color': AppColors.warningOrange,
        'unread': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTypography.headlineSm(isDark)),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
              );
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          final isUnread = item['unread'] as bool;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnread
                      ? AppColors.primary.withOpacity(0.5)
                      : (isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: (item['color'] as Color).withOpacity(0.12),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTypography.bodyLg(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                color: item['color'] as Color,
                                fontSize: 13,
                              ),
                            ),
                            Text(item['time'] as String, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item['desc'] as String, style: AppTypography.bodyMd(isDark)),
                      ],
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
