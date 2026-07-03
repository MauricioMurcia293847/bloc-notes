import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/note.dart';
import '../../notes/data/notes_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);

    return notesState.when(
      data: (notes) => _SearchContent(
        notes: notes,
        query: _query,
        controller: _queryController,
        onChanged: (value) => setState(() => _query = value),
        onClear: _clearQuery,
        onRecentSelected: _setQuery,
      ),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => _SearchErrorState(
        onRetry: () => ref.invalidate(notesProvider),
      ),
    );
  }

  void _clearQuery() {
    _queryController.clear();
    setState(() => _query = '');
  }

  void _setQuery(String value) {
    _queryController.text = value;
    _queryController.selection = TextSelection.collapsed(
      offset: _queryController.text.length,
    );
    setState(() => _query = value);
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({
    required this.notes,
    required this.query,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onRecentSelected,
  });

  final List<Note> notes;
  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onRecentSelected;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = normalizedQuery.isEmpty
        ? notes
        : notes.where((note) {
            return note.title.toLowerCase().contains(normalizedQuery) ||
                note.preview.toLowerCase().contains(normalizedQuery) ||
                note.folder.toLowerCase().contains(normalizedQuery);
          }).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.cancel_rounded),
                      ),
                      hintText: 'Buscar notas',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('RECIENTES', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecentChip(
                  label: 'trabajo',
                  onSelected: () => onRecentSelected('trabajo'),
                ),
                _RecentChip(
                  label: 'personal',
                  onSelected: () => onRecentSelected('personal'),
                ),
                _RecentChip(
                  label: 'ideas',
                  onSelected: () => onRecentSelected('ideas'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'RESULTADOS - ${results.length}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 42),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.sage.withValues(alpha: 0.14),
                        foregroundColor: AppColors.sage,
                        child: const Icon(Icons.search_off_rounded, size: 30),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin resultados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Intenta con otro titulo, carpeta o palabra.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...results.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => context.push(
                      note.id == null ? '/editor' : '/editor?id=${note.id}',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    tileColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.nightSurface
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(note.preview),
                    leading: note.imageUrls.isEmpty
                        ? null
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.network(
                                note.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: AppColors.sage.withValues(alpha: 0.16),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                  foregroundColor: AppColors.danger,
                  child: const Icon(Icons.search_off_rounded, size: 34),
                ),
                const SizedBox(height: 18),
                Text(
                  'No se pudo buscar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta actualizar tus notas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onSelected});

  final String label;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      onPressed: onSelected,
      label: Text(label),
      backgroundColor: isDark ? AppColors.nightSurface : AppColors.paperMuted,
      labelStyle: TextStyle(
        color: isDark ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
