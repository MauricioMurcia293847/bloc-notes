import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/preferences/app_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/folder.dart';
import '../../../core/models/note.dart';
import '../../notes/data/notes_repository.dart';
import '../../../shared/widgets/note_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedFolder;

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final foldersState = ref.watch(foldersProvider);
    final sortOrder = ref.watch(notesSortProvider);
    final viewMode = ref.watch(notesViewModeProvider);

    return notesState.when(
      data: (notes) => foldersState.when(
        data: (folders) => _HomeContent(
          notes: notes,
          folders: folders,
          sortOrder: sortOrder,
          viewMode: viewMode,
          onViewModeChanged: (mode) =>
              ref.read(notesViewModeProvider.notifier).setMode(mode),
          selectedFolder: _selectedFolder,
          onFolderSelected: (folder) => setState(() {
            _selectedFolder = folder == _selectedFolder ? null : folder;
          }),
        ),
        loading: () => _HomeContent(
          notes: notes,
          folders: mockFolders,
          sortOrder: sortOrder,
          viewMode: viewMode,
          onViewModeChanged: (mode) =>
              ref.read(notesViewModeProvider.notifier).setMode(mode),
          selectedFolder: _selectedFolder,
          onFolderSelected: (folder) => setState(() {
            _selectedFolder = folder == _selectedFolder ? null : folder;
          }),
        ),
        error: (_, _) => _HomeContent(
          notes: notes,
          folders: mockFolders,
          sortOrder: sortOrder,
          viewMode: viewMode,
          onViewModeChanged: (mode) =>
              ref.read(notesViewModeProvider.notifier).setMode(mode),
          selectedFolder: _selectedFolder,
          onFolderSelected: (folder) => setState(() {
            _selectedFolder = folder == _selectedFolder ? null : folder;
          }),
        ),
      ),
      loading: () => const _HomeLoading(),
      error: (_, _) => _HomeError(onRetry: () => ref.invalidate(notesProvider)),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.notes,
    required this.sortOrder,
    required this.viewMode,
    required this.onViewModeChanged,
    this.folders = mockFolders,
    this.selectedFolder,
    this.onFolderSelected,
  });

  final List<Note> notes;
  final NotesSortOrder sortOrder;
  final NotesViewMode viewMode;
  final ValueChanged<NotesViewMode> onViewModeChanged;
  final List<Folder> folders;
  final String? selectedFolder;
  final ValueChanged<String?>? onFolderSelected;

  @override
  Widget build(BuildContext context) {
    final filterFolders = _foldersFromData();
    final filteredNotes = selectedFolder == null
        ? notes
        : notes.where((note) => note.folder == selectedFolder).toList();
    final visibleNotes = _sortNotes(filteredNotes);
    final pinned = visibleNotes.where((note) => note.isPinned).toList();
    final others = visibleNotes.where((note) => !note.isPinned).toList();
    final userEmail = AppConfig.hasSupabaseConfig
        ? Supabase.instance.client.auth.currentUser?.email
        : null;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/editor'),
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis notas',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              Text(
                                '${visibleNotes.length} notas',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => context.push('/settings'),
                          child: CircleAvatar(
                            backgroundColor: AppColors.paperMuted,
                            foregroundColor: AppColors.inkMuted,
                            child: Text(_initials(userEmail)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            onTap: () => context.push('/search'),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Buscar notas',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          onPressed: () => onViewModeChanged(
                            NotesViewMode.grid,
                          ),
                          icon: const Icon(Icons.grid_view_rounded),
                          isSelected: viewMode == NotesViewMode.grid,
                        ),
                        IconButton(
                          onPressed: () => onViewModeChanged(
                            NotesViewMode.list,
                          ),
                          icon: const Icon(Icons.view_agenda_outlined),
                          isSelected: viewMode == NotesViewMode.list,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FolderFilters(
                      folders: filterFolders,
                      selectedFolder: selectedFolder,
                      onSelected: onFolderSelected,
                    ),
                  ],
                ),
              ),
            ),
            if (visibleNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNotesState(selectedFolder: selectedFolder),
              )
            else ...[
              if (pinned.isNotEmpty) ...[
                const _SectionHeader(title: 'FIJADAS'),
                _NotesSection(
                  notes: pinned,
                  viewMode: viewMode,
                  animationOffset: 0,
                ),
              ],
              if (others.isNotEmpty) ...[
                const _SectionHeader(title: 'TODAS'),
                _NotesSection(
                  notes: others,
                  viewMode: viewMode,
                  animationOffset: pinned.length,
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 92)),
          ],
        ),
      ),
    );
  }

  List<Note> _sortNotes(List<Note> source) {
    final sorted = [...source];

    switch (sortOrder) {
      case NotesSortOrder.recent:
        return sorted;
      case NotesSortOrder.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case NotesSortOrder.folder:
        sorted.sort((a, b) {
          final folder = a.folder.compareTo(b.folder);
          if (folder != 0) {
            return folder;
          }

          return a.title.compareTo(b.title);
        });
    }

    return sorted;
  }

  String _initials(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) {
      return 'BL';
    }

    return value[0].toUpperCase();
  }

  List<Folder> _foldersFromData() {
    final byName = <String, Folder>{
      for (final folder in mockFolders) folder.name: folder,
      for (final folder in folders) folder.name: folder,
    };

    for (final note in notes) {
      if (!byName.containsKey(note.folder)) {
        byName[note.folder] = Folder(
          id: note.folder.toLowerCase(),
          name: note.folder,
          position: byName.length + 1,
        );
      }
    }

    final merged = byName.values.toList()
      ..sort((a, b) {
        final position = a.position.compareTo(b.position);
        if (position != 0) {
          return position;
        }

        return a.name.compareTo(b.name);
      });

    return merged;
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonLine(width: 150, height: 30),
              const SizedBox(height: 10),
              const _SkeletonLine(width: 68, height: 14),
              const SizedBox(height: 26),
              const _SkeletonLine(width: double.infinity, height: 54),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (_, _) => const _SkeletonCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

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
                  child: const Icon(Icons.sync_problem_rounded, size: 34),
                ),
                const SizedBox(height: 18),
                Text(
                  'No se pudieron cargar tus notas',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexion o intenta de nuevo.',
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
        ),
      ),
    );
  }
}

class _FolderFilters extends StatelessWidget {
  const _FolderFilters({
    required this.folders,
    required this.selectedFolder,
    required this.onSelected,
  });

  final List<Folder> folders;
  final String? selectedFolder;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = ['Todas', ...folders.map((folder) => folder.name)];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.ink;
    final inactiveBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.ink.withValues(alpha: 0.18);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = labels[index];
          final isActive = selectedFolder == null
              ? index == 0
              : label == selectedFolder;
          return ChoiceChip(
            selected: isActive,
            label: Text(label),
            onSelected: (_) => onSelected?.call(index == 0 ? null : label),
            selectedColor: AppColors.sage,
            backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : inactiveTextColor,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: isActive ? AppColors.sage : inactiveBorderColor,
            ),
            showCheckmark: false,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: labels.length,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.72)
                : AppColors.inkMuted,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState({this.selectedFolder});

  final String? selectedFolder;

  @override
  Widget build(BuildContext context) {
    final hasFolderFilter = selectedFolder != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.sage.withValues(alpha: 0.16),
            foregroundColor: AppColors.sage,
            child: const Icon(Icons.edit_note_rounded, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            hasFolderFilter
                ? 'Sin notas en $selectedFolder'
                : 'Todavia no tienes notas',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            hasFolderFilter
                ? 'Cambia de filtro o crea una nota nueva para esta carpeta.'
                : 'Crea la primera y la guardamos en Supabase.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/editor'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva nota'),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.viewMode,
    required this.animationOffset,
  });

  final List<Note> notes;
  final NotesViewMode viewMode;
  final int animationOffset;

  @override
  Widget build(BuildContext context) {
    if (viewMode == NotesViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: notes.length,
          itemBuilder: (context, index) => _StaggeredNoteCard(
            delayIndex: animationOffset + index,
            child: _NoteListTile(note: notes[index]),
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final crossAxisCount = width >= 760 ? 3 : 2;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.builder(
            itemCount: notes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: width >= 760 ? 1.02 : 0.86,
            ),
            itemBuilder: (context, index) => _StaggeredNoteCard(
              delayIndex: animationOffset + index,
              child: NoteCard(note: notes[index]),
            ),
          ),
        );
      },
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFB7B0A5) : AppColors.inkMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(
        note.id == null ? '/editor' : '/editor?id=${note.id}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (note.imageUrls.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.network(
                    note.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: AppColors.sage.withValues(alpha: 0.16),
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (note.isPinned)
                        const Icon(Icons.push_pin_rounded, size: 15),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.checklistItems.isNotEmpty
                        ? note.checklistItems
                              .map((item) => item.label)
                              .where((label) => label.trim().isNotEmpty)
                              .take(3)
                              .join(', ')
                        : note.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${note.folder} - ${note.dateLabel}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _StaggeredNoteCard extends StatefulWidget {
  const _StaggeredNoteCard({required this.delayIndex, required this.child});

  final int delayIndex;
  final Widget child;

  @override
  State<_StaggeredNoteCard> createState() => _StaggeredNoteCardState();
}

class _StaggeredNoteCardState extends State<_StaggeredNoteCard> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 35 * widget.delayIndex), () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: _isVisible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0, 0.04),
        child: widget.child,
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.nightSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.nightSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
