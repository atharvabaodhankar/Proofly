import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const AuthScreen({super.key, this.initialIsSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _orgNameController = TextEditingController();
  String _selectedRole = 'recipient'; // 'recipient' or 'org_admin'

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    if (!_isSignUp) {
      _emailController.text = 'alex.rivera@techinst.edu';
      _passwordController.text = 'Password@123';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    final navigator = Navigator.of(context);

    if (_isSignUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name.')),
        );
        return;
      }

      final success = await auth.register(
        email: email,
        password: password,
        name: name,
        role: _selectedRole,
        orgName: _selectedRole == 'org_admin' ? _orgNameController.text.trim() : null,
      );

      if (success && mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    } else {
      final success = await auth.login(email, password);
      if (success && mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              Text(
                _isSignUp ? 'Create an Account' : 'Welcome Back',
                style: AppTypography.headlineLg(isDark),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Register to receive or issue verifiable blockchain credentials.'
                    : 'Sign in to access your blockchain credential wallet.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(isDark),
              ),
              const SizedBox(height: 24),

              // Mode Toggle Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceLowLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSignUp = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: !_isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isSignUp = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: _isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.outlineVariantDark : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isSignUp) ...[
                      Text('Full Name', style: AppTypography.labelSm(isDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Jane Doe',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Account Type', style: AppTypography.labelSm(isDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Recipient')),
                              selected: _selectedRole == 'recipient',
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: _selectedRole == 'recipient' ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedRole = 'recipient');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Issuer / Org')),
                              selected: _selectedRole == 'org_admin',
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: _selectedRole == 'org_admin' ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedRole = 'org_admin');
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedRole == 'org_admin') ...[
                        const SizedBox(height: 16),
                        Text('Organization Name', style: AppTypography.labelSm(isDark)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _orgNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Tech Institute Global',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    Text('Email Address', style: AppTypography.labelSm(isDark)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'name@organization.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: AppTypography.labelSm(isDark)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSubmit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_isSignUp ? 'Create Real Account' : 'Sign In to Proofly'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'LIVE ON POLYGON AMOY BLOCKCHAIN',
                style: AppTypography.labelSm(isDark).copyWith(fontSize: 10, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
