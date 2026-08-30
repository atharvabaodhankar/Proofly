import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'home/recipient_home_screen.dart';
import 'issuer/issuer_dashboard_screen.dart';
import 'verification/verify_screen.dart';
import 'settings/settings_screen.dart';
import 'notifications/notifications_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const RecipientHomeScreen(),
    const IssuerDashboardScreen(),
    const VerifyScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.85),
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Text(
              'Proofly',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white : AppColors.textMainLight,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: const Text('AR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
                _buildNavItem(1, Icons.dashboard_customize_rounded, 'Issuer', isDark),
                _buildNavItem(2, Icons.verified_user_rounded, 'Verify', isDark),
                _buildNavItem(3, Icons.account_circle_rounded, 'Profile', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : (isDark ? AppColors.outlineDark : AppColors.outlineLight);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
