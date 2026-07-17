import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/widgets/bloc_app_mark.dart';
import 'auth_error_message.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isSendingReset = false;
  bool _obscurePassword = true;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            const Center(child: BlocAppMark(size: 48)),
            const SizedBox(height: 24),
            Text(
              _isSignUp ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.paperMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _AuthModeButton(
                      isActive: !_isSignUp,
                      label: 'Iniciar sesion',
                      onPressed: () => setState(() => _isSignUp = false),
                    ),
                  ),
                  Expanded(
                    child: _AuthModeButton(
                      isActive: _isSignUp,
                      label: 'Crear cuenta',
                      onPressed: () => setState(() => _isSignUp = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('CORREO', style: textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'maria@correo.com'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 18),
            Text('CONTRASENA', style: textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
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
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendPasswordReset,
                  child: Text(
                    _isSendingReset
                        ? 'Enviando...'
                        : 'Olvidaste tu contrasena?',
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
            if (_message != null) ...[
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: _messageColor()),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: Text(
                _isLoading
                    ? 'Conectando...'
                    : _isSignUp
                    ? 'Crear cuenta'
                    : 'Iniciar sesion',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o continua con', style: textTheme.bodyMedium),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setMessage(
                      'Google se conectara en una fase posterior.',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: const Text('Google'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setMessage(
                      'Apple se conectara en una fase posterior.',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.apple_rounded),
                    label: const Text('Apple'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!AppConfig.hasSupabaseConfig) {
      context.go('/home');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _setMessage('Escribe tu correo y contrasena.', isError: true);
        return;
      }

      if (!_isValidEmail(email)) {
        _setMessage('Escribe un correo valido.', isError: true);
        return;
      }

      if (password.length < 6) {
        _setMessage(
          'La contrasena debe tener al menos 6 caracteres.',
          isError: true,
        );
        return;
      }

      if (_isSignUp) {
        await auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'blocnotes://auth-callback',
        );
        _setMessage(
          'Mensaje de Supabase: enviamos un correo de verificacion. Abre el enlace desde este dispositivo para activar tu cuenta.',
        );
        setState(() => _isSignUp = false);
      } else {
        await auth.signInWithPassword(email: email, password: password);
        if (mounted) {
          context.go('/home');
        }
      }
    } on AuthException catch (error) {
      _setMessage(friendlyAuthError(error), isError: true);
    } catch (error) {
      _setMessage(friendlyAuthError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (!AppConfig.hasSupabaseConfig) {
      _setMessage(
        'Configura Supabase para recuperar contrasena.',
        isError: true,
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setMessage('Escribe tu correo primero.', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _setMessage('Escribe un correo valido.', isError: true);
      return;
    }

    setState(() {
      _isSendingReset = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'blocnotes://reset-password',
      );
      _setMessage('Te enviamos instrucciones al correo.');
    } on AuthException catch (error) {
      _setMessage(friendlyAuthError(error), isError: true);
    } catch (error) {
      _setMessage(friendlyAuthError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  Color _messageColor() {
    return _messageIsError ? AppColors.danger : AppColors.sage;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.isActive,
    required this.label,
    required this.onPressed,
  });

  final bool isActive;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      );
    }

    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
