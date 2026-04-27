import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/aegis_button.dart';
import '../widgets/aegis_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final error = await context.read<AuthService>().signUp(email, pass, name);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() { _loading = false; _error = error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: aegisCream,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [aegisPinkLight, aegisPinkPale],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AEGIS',
                    style: AppTextStyles.h1.copyWith(
                      color: aegisPinkDark,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account',
                    style: AppTextStyles.h2.copyWith(color: aegisText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor. Protect. Connect.',
                    style: AppTextStyles.caption.copyWith(color: aegisTextMid),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: aegisCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Sign up', style: AppTextStyles.h3),
                      const SizedBox(height: 24),
                      AegisTextField(
                        label: 'Full name',
                        hint: 'Your name',
                        controller: _nameCtrl,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),
                      AegisTextField(
                        label: 'Email',
                        hint: 'parent@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AegisTextField(
                        label: 'Password',
                        hint: 'At least 6 characters',
                        controller: _passCtrl,
                        obscure: true,
                      ),
                      const SizedBox(height: 16),
                      AegisTextField(
                        label: 'Confirm password',
                        hint: 'Re-enter your password',
                        controller: _confirmPassCtrl,
                        obscure: true,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: AppTextStyles.caption
                              .copyWith(color: statusAlert),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AegisButton(
                        label: 'Create Account',
                        onPressed: _signUp,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.caption,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            child: Text(
                              'Sign in',
                              style: AppTextStyles.caption
                                  .copyWith(color: aegisPinkDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
