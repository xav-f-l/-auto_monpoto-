import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/theme/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  double _passwordStrength = 0;
  String? _emailError;

  static final _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (value.contains(RegExp(r'[!@#$%^&*]'))) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez accepter les conditions d'utilisation"),
        ),
      );
      return;
    }
    ref.read(authProvider.notifier).register(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.emailNotVerified) {
        context.go('/verify-email');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez Auto Monpoto',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                label: 'Nom',
                                hint: 'Votre nom',
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                label: 'Prénom',
                                hint: 'Votre prénom',
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'exemple@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: _emailError,
                          onChanged: (_) {
                            final email = _emailController.text;
                            if (email.isEmpty) {
                              setState(() => _emailError = null);
                            } else if (!_emailRegex.hasMatch(email)) {
                              setState(() => _emailError = 'Email invalide');
                            } else {
                              setState(() => _emailError = null);
                            }
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email requis';
                            if (!_emailRegex.hasMatch(v)) return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          hint: '0601020304',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Téléphone requis';
                            final clean = v.replaceAll(' ', '').replaceAll('-', '');
                            if (clean.length < 8 ||
                                !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(clean)) {
                              return 'Numéro invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: 'Minimum 8 caractères',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          onChanged: _checkPasswordStrength,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Mot de passe requis';
                            if (v.length < 8) return 'Minimum 8 caractères';
                            if (!v.contains(RegExp(r'[A-Z]'))) {
                              return 'Doit contenir une majuscule';
                            }
                            if (!v.contains(RegExp(r'[0-9]'))) {
                              return 'Doit contenir un chiffre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            minHeight: 4,
                            backgroundColor: AppColors.border,
                            color: _passwordStrength < 0.5
                                ? AppColors.error
                                : _passwordStrength < 0.75
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _passwordStrength < 0.5
                                ? 'Faible'
                                : _passwordStrength < 0.75
                                    ? 'Moyen'
                                    : 'Fort',
                            style: TextStyle(
                              fontSize: 12,
                              color: _passwordStrength < 0.5
                                  ? AppColors.error
                                  : _passwordStrength < 0.75
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          hint: 'Répétez le mot de passe',
                          obscureText: _obscureConfirm,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        if (authState.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authState.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _acceptedTerms,
                                activeColor: AppColors.primary,
                                onChanged: (v) =>
                                    setState(() => _acceptedTerms = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: "J'accepte les ",
                                      ),
                                      TextSpan(
                                        text: "Conditions d'utilisation",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: "S'inscrire",
                          isLoading: authState.status == AuthStatus.loading,
                          onPressed: _handleRegister,
                          icon: Icons.person_add,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Déjà un compte ?'),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Se connecter'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
