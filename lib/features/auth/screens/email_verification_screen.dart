import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _resent = false;

  Future<void> _resendEmail() async {
    await ref.read(authProvider.notifier).resendVerificationEmail();
    setState(() => _resent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_outlined,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text('Vérifiez votre email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Un lien de confirmation a été envoyé à :\n${FirebaseAuth.instance.currentUser?.email ?? "votre email"}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              if (_resent)
                const Text('Email renvoyé \u2705',
                    style: TextStyle(color: AppColors.success)),
              if (!_resent)
                TextButton(
                  onPressed: _resendEmail,
                  child: const Text("Renvoyer l'email"),
                ),
              const SizedBox(height: 16),
              CustomButton(
                text: "J'ai vérifié mon email",
                onPressed: () async {
                  await ref.read(authProvider.notifier).checkEmailVerified();
                  final authState = ref.read(authProvider);
                  if (authState.status == AuthStatus.authenticated) {
                    if (authState.isAdmin) {
                      context.go('/admin');
                    } else {
                      context.go('/home');
                    }
                  } else if (authState.error != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authState.error!)),
                      );
                    }
                  }
                },
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
