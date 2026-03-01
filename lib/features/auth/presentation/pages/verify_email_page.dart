import 'dart:async';
import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isResendLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Opcional: Verifica periodicamente se o usuário validou
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    await context.read<AuthNotifier>().checkEmailVerification();
  }

  Future<void> _resendEmail() async {
    setState(() => _isResendLoading = true);
    try {
      await context.read<AuthRepository>().sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail reenviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResendLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select((AuthNotifier n) => n.user?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar E-mail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthNotifier>().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Verifique sua caixa de entrada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enviamos um link de verificação para:\n$email\n\nPor favor, verifique também sua caixa de spam ou lixo eletrônico.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _checkVerification,
                child: const Text('JÁ VERIFIQUEI'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isResendLoading ? null : _resendEmail,
              child: _isResendLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reenviar e-mail'),
            ),
          ],
        ),
      ),
    );
  }
}