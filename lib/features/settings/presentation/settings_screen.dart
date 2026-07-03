import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/preferences/app_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../notes/data/notes_repository.dart';
import '../data/profile_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textSize = ref.watch(textSizeProvider);
    final sortOrder = ref.watch(notesSortProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(profileProvider);
    final foldersCount = ref.watch(foldersProvider).maybeWhen(
          data: (folders) => folders.length.toString(),
          orElse: () => '-',
        );
    final deletedCount = ref.watch(deletedNotesProvider).maybeWhen(
          data: (notes) => notes.length.toString(),
          orElse: () => '-',
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          'Ajustes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            profileState.when(
              data: (profile) => _ProfileTile(
                isDark: isDark,
                profile: profile,
                onTap: profile == null ? null : () => _showEditProfile(profile),
              ),
              loading: () => _ProfileTile.loading(isDark: isDark),
              error: (_, _) => _ProfileTile(
                isDark: isDark,
                profile: null,
                onTap: null,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'APARIENCIA'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.dark_mode_rounded,
                  iconColor: isDark ? AppColors.paperMuted : AppColors.ink,
                  title: 'Modo oscuro',
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) =>
                        ref.read(themeModeProvider.notifier).setDarkMode(value),
                  ),
                ),
                const _SettingsDivider(),
                _SettingsRow(
                  icon: Icons.text_fields_rounded,
                  iconColor: AppColors.blue,
                  title: 'Tamano de texto',
                  trailingText: textSize.label,
                  showChevron: true,
                  onTap: _showTextSizeOptions,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'NOTAS'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.folder_rounded,
                  iconColor: AppColors.clay,
                  title: 'Carpetas',
                  trailingText: foldersCount,
                  showChevron: true,
                  onTap: _showFolders,
                ),
                const _SettingsDivider(),
                _SettingsRow(
                  icon: Icons.sort_rounded,
                  iconColor: AppColors.sage,
                  title: 'Ordenar por',
                  trailingText: sortOrder.label,
                  showChevron: true,
                  onTap: _showSortOptions,
                ),
                const _SettingsDivider(),
                _SettingsRow(
                  icon: Icons.delete_rounded,
                  iconColor: AppColors.lavender,
                  title: 'Papelera',
                  trailingText: deletedCount,
                  showChevron: true,
                  onTap: () => context.push('/trash'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isSigningOut ? null : _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppColors.inkMuted.withValues(alpha: 0.65),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSigningOut ? 'Cerrando sesion...' : 'Cerrar sesion',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bloc - version 1.0',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showFolders() {
    final foldersState = ref.read(foldersProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Carpetas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              foldersState.when(
                data: (folders) => folders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Todavia no tienes carpetas.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Column(
                        children: folders
                            .map(
                              (folder) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _folderColor(folder.color),
                                  child: const Icon(
                                    Icons.folder_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(folder.name),
                                trailing: Text('#${folder.position}'),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No se pudieron cargar las carpetas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _folderColor(String? value) {
    final colorText = value?.replaceFirst('#', '');
    if (colorText == null || colorText.length != 6) {
      return AppColors.sage;
    }

    return Color(int.parse('FF$colorText', radix: 16));
  }

  void _showTextSizeOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _OptionSheet<AppTextSize>(
        title: 'Tamano de texto',
        values: AppTextSize.values,
        selected: ref.read(textSizeProvider),
        labelFor: (value) => value.label,
        onSelected: (value) {
          ref.read(textSizeProvider.notifier).setSize(value);
          context.pop();
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _OptionSheet<NotesSortOrder>(
        title: 'Ordenar notas',
        values: NotesSortOrder.values,
        selected: ref.read(notesSortProvider),
        labelFor: (value) => value.label,
        onSelected: (value) {
          ref.read(notesSortProvider.notifier).setOrder(value);
          ref.invalidate(notesProvider);
          context.pop();
        },
      ),
    );
  }

  void _showEditProfile(UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EditProfileSheet(
        profile: profile,
        onSave: (fullName) async {
          await ref.read(profileRepositoryProvider).updateFullName(fullName);
          ref.invalidate(profileProvider);
        },
      ),
    );
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.16),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
          ),
        ),
        title: const Text('Cerrar sesion?'),
        content: const Text(
          'Tendras que iniciar sesion de nuevo para ver tus notas.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                dialogContext.pop();
                await _signOut();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Cerrar sesion'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => dialogContext.pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(profileProvider);
      ref.invalidate(notesProvider);
      ref.invalidate(foldersProvider);
      ref.invalidate(deletedNotesProvider);

      if (mounted) {
        context.go('/auth');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            for (final value in values)
              ListTile(
                onTap: () => onSelected(value),
                contentPadding: EdgeInsets.zero,
                title: Text(labelFor(value)),
                trailing: value == selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.sage,
                      )
                    : const Icon(Icons.circle_outlined),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.profile,
    required this.onSave,
  });

  final UserProfile profile;
  final Future<void> Function(String fullName) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.fullName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text('NOMBRE', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Tu nombre'),
            ),
            const SizedBox(height: 12),
            Text(
              widget.profile.email ?? 'Sin correo activo',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Guardando...' : 'Guardar perfil'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    var didPop = false;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.onSave(_controller.text);

      if (mounted) {
        didPop = true;
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No se pudo guardar el perfil.');
      }
    } finally {
      if (mounted && !didPop) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.isDark,
    required this.profile,
    required this.onTap,
  }) : _isLoading = false;

  const _ProfileTile.loading({required this.isDark})
      : profile = null,
        onTap = null,
        _isLoading = true;

  final bool isDark;
  final UserProfile? profile;
  final VoidCallback? onTap;
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.paperMuted,
              foregroundColor: AppColors.inkMuted,
              backgroundImage: _avatarImage(currentProfile?.avatarUrl),
              child: _avatarImage(currentProfile?.avatarUrl) == null
                  ? Text(
                      _isLoading ? '...' : currentProfile?.initials ?? 'BL',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoading
                        ? 'Cargando perfil'
                        : currentProfile?.displayName ?? 'Cuenta activa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentProfile?.email ?? 'Sin correo activo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.edit_rounded),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String? avatarUrl) {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAbsolutePath) {
      return null;
    }

    return NetworkImage(value);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.72)
            : AppColors.inkMuted,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.nightSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.trailingText,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final String? trailingText;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 66,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (trailingText != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (showChevron) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ],
                )
              else if (showChevron)
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : AppColors.ink.withValues(alpha: 0.06),
    );
  }
}
