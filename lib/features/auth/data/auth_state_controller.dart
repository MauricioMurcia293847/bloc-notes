import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

final authStateControllerProvider = Provider<AuthStateController>((ref) {
  final controller = AuthStateController();
  ref.onDispose(controller.dispose);
  return controller;
});

class AuthStateController extends ChangeNotifier {
  AuthStateController() {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    _appLinks = AppLinks();
    _linkSubscription = _appLinks?.uriLinkStream.listen(_handleAuthLink);
    unawaited(_handleInitialAuthLink());

    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }

      notifyListeners();
    });
  }

  AppLinks? _appLinks;
  StreamSubscription<AuthState>? _subscription;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isPasswordRecovery = false;

  bool get isSignedIn {
    if (!AppConfig.hasSupabaseConfig) {
      return false;
    }

    return Supabase.instance.client.auth.currentSession != null;
  }

  bool get isPasswordRecovery => _isPasswordRecovery;

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  Future<void> _handleInitialAuthLink() async {
    try {
      final uri = await _appLinks?.getInitialLink();
      if (uri != null) {
        _handleAuthLink(uri);
      }
    } catch (_) {
      // The Supabase listener still handles valid auth links if this fails.
    }
  }

  void _handleAuthLink(Uri uri) {
    final fragmentParameters = Uri.splitQueryString(uri.fragment);
    final type = uri.queryParameters['type'] ?? fragmentParameters['type'];
    final isResetLink = uri.scheme == 'blocnotes' &&
        uri.host == 'reset-password';

    if (isResetLink || type == 'recovery') {
      _isPasswordRecovery = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
