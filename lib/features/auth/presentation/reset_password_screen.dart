import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../data/auth_state_controller.dart';
import 'auth_error_message.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.sage.withValues(alpha: 0.16),
              foregroundColor: AppColors.sage,
              child: const Icon(Icons.lock_reset_rounded, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Crea una nueva contrasena',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Usa una contrasena de al menos 6 caracteres.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Text('NUEVA CONTRASENA', style: textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: '********',
                suffixIcon: IconButton(
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('CONFIRMAR CONTRASENA', style: textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _updatePassword(),
              decoration: const InputDecoration(hintText: '********'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: _messageColor()),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _isLoading ? null : _updatePassword,
              child: Text(_isLoading ? 'Guardando...' : 'Guardar contrasena'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _returnToSignIn,
              child: const Text('Volver a iniciar sesion'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      setState(() {
        _message =
            'Abre el enlace nuevo del correo para validar la recuperacion.';
        _messageIsError = true;
      });
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() {
        _message = 'La contrasena debe tener al menos 6 caracteres.';
        _messageIsError = true;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _message = 'Las contrasenas no coinciden.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      ref.read(authStateControllerProvider).clearPasswordRecovery();
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        context.go('/auth?notice=password-updated');
      }
    } on AuthException catch (error) {
      setState(() {
        _message = friendlyAuthError(error);
        _messageIsError = true;
      });
    } catch (error) {
      setState(() {
        _message = friendlyAuthError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _returnToSignIn() {
    ref.read(authStateControllerProvider).clearPasswordRecovery();
    context.go('/auth');
  }

  Color _messageColor() {
    return _messageIsError ? AppColors.danger : AppColors.sage;
  }
}
