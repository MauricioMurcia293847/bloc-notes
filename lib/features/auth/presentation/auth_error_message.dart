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
    return 'Correo o contrasena incorrectos.';
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
