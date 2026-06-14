// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/catusnis_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    context.read<AuthProvider>().clearError();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D3380),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ══ ZONE LOGO ══════════════════════════════════════
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: Column(
                    children: [
                      // ✅ GIF logo sur login
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/catusnis_animation.gif',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const CatusnisLogo(size: 120),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CatusnisText(fontSize: 28),
                      const SizedBox(height: 8),
                      const Text(
                        'Centre d\'Assistance Technique\naux Utilisateurs du S.N.I.S',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // ══ ZONE FORMULAIRE ════════════════════════════════
              SlideTransition(
                position: _slideAnim,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 400),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A2A6E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Connexion',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        const Text('Entrez vos identifiants CATUSNIS',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 28),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            label: 'Adresse email',
                            hint: 'exemple@catusnis.ci',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'L\'email est requis';
                            if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
                                .hasMatch(v.trim())) return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mot de passe
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white60,
                              ),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Le mot de passe est requis';
                            if (v.length < 4) return 'Minimum 4 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        if (auth.error != null) ...[
                          _buildError(auth.error!),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6F00),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Se connecter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text('CATUSNIS Mobile v1.0.0',
                              style: TextStyle(
                                  color: Colors.white30, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6F00), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1)),
      );

  Widget _buildError(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: AppTheme.danger, fontSize: 13))),
        ]),
      );
}
