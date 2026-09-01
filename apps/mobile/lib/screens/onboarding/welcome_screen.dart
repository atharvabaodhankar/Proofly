import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Issue',
      'desc': 'Organizations anchor credentials directly to Polygon Amoy blockchain, ensuring absolute permanence.',
      'icon': Icons.assured_workload_rounded,
    },
    {
      'title': 'Store',
      'desc': 'Securely manage your professional achievements in one place, totally under your control.',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'title': 'Verify',
      'desc': 'Instant, tamper-proof cryptographic verification for anyone, anywhere, with zero friction.',
      'icon': Icons.verified_user_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Proofly Logo & Tagline
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Digital credentials\nyou can prove',
                    textAlign: TextAlign.center,
                    style: AppTypography.display(isDark).copyWith(fontSize: 32, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Swipeable Cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(slide['icon'] as IconData, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide['title'] as String,
                            style: AppTypography.headlineMd(isDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide['desc'] as String,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd(isDark).copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.outlineVariantLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen(initialIsSignUp: true)),
                        );
                      },
                      child: const Text('GET STARTED (CREATE ACCOUNT)', style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen(initialIsSignUp: false)),
                        );
                      },
                      child: const Text('LOG IN TO PROOFLY', style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
