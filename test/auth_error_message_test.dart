import 'package:bloc_notes/features/auth/presentation/auth_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendlyAuthError', () {
    test(
      'keeps invalid credentials separate from email verification state',
      () {
        final message = friendlyAuthError('Invalid login credentials');

        expect(message, contains('No pudimos iniciar sesion'));
        expect(message.toLowerCase(), isNot(contains('verificada')));
      },
    );

    test('explains Supabase email limits as a project cooldown', () {
      final message = friendlyAuthError('email rate limit exceeded');

      expect(message, contains('correos del proyecto'));
      expect(message, contains('Espera unos minutos'));
    });
  });
}
