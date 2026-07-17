String friendlyAuthError(Object error) {
  final message = error.toString();
  final lower = message.toLowerCase();

  if (lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection timed out')) {
    return 'No pudimos conectar con Supabase. Revisa tu internet, datos moviles, VPN o DNS e intenta de nuevo.';
  }

  if (lower.contains('invalid login credentials')) {
    return 'No pudimos iniciar sesion con esos datos. Revisa el correo y escribe exactamente tu contrasena actual. Si la cambiaste hace poco, usa la nueva.';
  }

  if (lower.contains('over_email_send_rate_limit') ||
      lower.contains('email rate limit exceeded') ||
      lower.contains('rate limit')) {
    return 'Supabase limito temporalmente el envio de correos del proyecto por varios intentos. Espera unos minutos antes de solicitar otro correo.';
  }

  if (lower.contains('user already registered') ||
      lower.contains('already registered')) {
    return 'Ese correo ya tiene una cuenta. Inicia sesion o recupera tu contrasena.';
  }

  if (lower.contains('email') && lower.contains('invalid')) {
    return 'Escribe un correo valido.';
  }

  if (lower.contains('password') && lower.contains('weak')) {
    return 'Usa una contrasena mas segura.';
  }

  return 'No se pudo completar la accion. Intenta de nuevo.';
}
