import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String fullName;
  final String? avatarUrl;

  String get displayName {
    final trimmedName = fullName.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      return trimmedEmail.split('@').first;
    }

    return 'Cuenta activa';
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) {
      return 'BL';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return source[0].toUpperCase();
  }
}

class ProfileRepository {
  Future<UserProfile?> fetchProfile() async {
    if (!AppConfig.hasSupabaseConfig) {
      return const UserProfile(
        id: 'mock',
        email: 'maria@correo.com',
        fullName: 'Maria Rodriguez',
      );
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final row = await client
        .from('profiles')
        .select('id, full_name, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return UserProfile(id: user.id, email: user.email, fullName: '');
    }

    return UserProfile(
      id: user.id,
      email: user.email,
      fullName: row['full_name'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  Future<void> updateFullName(String fullName) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Necesitas iniciar sesion para editar tu perfil.');
    }

    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName.trim(),
    });
  }
}
