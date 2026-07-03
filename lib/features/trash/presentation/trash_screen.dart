import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/note.dart';
import '../../notes/data/notes_repository.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedNotesState = ref.watch(deletedNotesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          'Papelera',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: deletedNotesState.when(
          data: (notes) => notes.isEmpty
              ? const _TrashEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemBuilder: (context, index) => _DeletedNoteTile(
                    note: notes[index],
                    onRestore: () => _restoreNote(context, ref, notes[index]),
                    onDelete: () => _confirmPermanentDelete(
                      context,
                      ref,
                      notes[index],
                    ),
                  ),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: notes.length,
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _TrashErrorState(
            onRetry: () => ref.invalidate(deletedNotesProvider),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreNote(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final id = note.id;
    if (id == null) {
      return;
    }

    try {
      await ref.read(notesRepositoryProvider).restoreNote(id);
      ref.invalidate(notesProvider);
      ref.invalidate(deletedNotesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota restaurada.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo restaurar la nota.')),
        );
      }
    }
  }

  void _confirmPermanentDelete(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.16),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.danger,
          ),
        ),
        title: const Text('Eliminar definitivamente?'),
        content: Text(
          'Se eliminara "${note.title}" de forma permanente.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final id = note.id;
                try {
                  if (id != null) {
                    await ref
                        .read(notesRepositoryProvider)
                        .permanentlyDeleteNote(id);
                    ref.invalidate(notesProvider);
                    ref.invalidate(deletedNotesProvider);
                  }

                  if (dialogContext.mounted) {
                    dialogContext.pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota eliminada.')),
                    );
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    dialogContext.pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo eliminar la nota.'),
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Eliminar'),
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
}

class _TrashErrorState extends StatelessWidget {
  const _TrashErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.danger.withValues(alpha: 0.14),
              foregroundColor: AppColors.danger,
              child: const Icon(Icons.sync_problem_rounded, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'No se pudo cargar la papelera',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta actualizar la lista.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedNoteTile extends StatelessWidget {
  const _DeletedNoteTile({
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            note.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restaurar'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Eliminar definitivamente',
                onPressed: onDelete,
                color: AppColors.danger,
                icon: const Icon(Icons.delete_forever_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrashEmptyState extends StatelessWidget {
  const _TrashEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.sage.withValues(alpha: 0.16),
              foregroundColor: AppColors.sage,
              child: const Icon(Icons.delete_outline_rounded, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'Papelera vacia',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Las notas eliminadas apareceran aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
