import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/folder.dart';
import '../../../core/models/note.dart';
import '../../notes/data/notes_repository.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _noteId;
  String? _folderId;
  String _folder = 'Personal';
  bool _isPinned = false;
  bool _isChecklist = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _messageIsError = false;
  bool _didChangeImages = false;
  TextAlign _bodyTextAlign = TextAlign.left;
  String? _message;
  final List<_ChecklistDraft> _checklistItems = [];
  final List<String> _imageUrls = [];
  final List<XFile> _pendingImages = [];

  bool get _isExistingNote => _noteId != null;

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId;
    if (_noteId != null) {
      _loadNote();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    for (final item in _checklistItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _isExistingNote && !_isLoading;
    final folders = ref.watch(foldersProvider).value ?? mockFolders;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleBackPressed,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          _isExistingNote ? 'Editar nota' : 'Nueva nota',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: _isPinned ? 'Desfijar' : 'Fijar',
            onPressed: _isLoading ? null : _togglePin,
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Guardar',
            onPressed: _isLoading || _isSaving ? null : _saveNote,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
          IconButton(
            tooltip: 'Mas opciones',
            onPressed: canDelete ? () => _showDeleteDialog(context) : null,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Checklist',
                onPressed: _toggleChecklistMode,
                icon: Icon(
                  Icons.checklist_rounded,
                  color: _isChecklist ? AppColors.sage : null,
                ),
              ),
              IconButton(
                tooltip: 'Agregar elemento',
                onPressed: _addChecklistItemFromToolbar,
                icon: const Icon(Icons.add_box_outlined),
              ),
              IconButton(
                tooltip: 'Imagen',
                onPressed: _pickImages,
                icon: const Icon(Icons.image_outlined, size: 22),
              ),
              IconButton(
                tooltip: 'Texto',
                onPressed: _switchToTextMode,
                icon: Icon(
                  Icons.text_fields_rounded,
                  color: !_isChecklist ? AppColors.sage : null,
                ),
              ),
              IconButton(
                tooltip: 'Alinear texto',
                onPressed: _cycleBodyTextAlign,
                icon: Icon(_textAlignIcon(), size: 22),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                children: [
                  Text(
                    _message ?? 'Editada hace un momento',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _messageIsError ? AppColors.danger : null,
                      fontWeight: _messageIsError ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Titulo',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: 'Sin recordatorio',
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Cambiar carpeta',
                        onSelected: (folderId) => _selectFolder(
                          folders.firstWhere(
                            (folder) => folder.id == folderId,
                          ),
                        ),
                        itemBuilder: (context) => folders
                            .map(
                              (folder) => PopupMenuItem(
                                value: folder.id,
                                child: Text(folder.name),
                              ),
                            )
                            .toList(),
                        child: _MetaPill(icon: Icons.circle, label: _folder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_imageUrls.isNotEmpty || _pendingImages.isNotEmpty) ...[
                    _ImagePreviewStrip(
                      imageUrls: _imageUrls,
                      pendingImages: _pendingImages,
                      onRemoveUrl: _removeImageUrl,
                      onRemovePending: _removePendingImage,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_isChecklist)
                    _ChecklistEditor(
                      items: _checklistItems,
                      onChanged: () => setState(() {}),
                      onAdd: _addChecklistItem,
                    )
                  else
                    TextField(
                      controller: _bodyController,
                      minLines: 10,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      textAlign: _bodyTextAlign,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Escribe tu nota...',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final note = await ref.read(notesRepositoryProvider).fetchNoteById(
        _noteId!,
      );

      if (note == null) {
      setState(() {
        _message = 'No encontramos esta nota.';
        _messageIsError = true;
      });
        return;
      }

      _titleController.text = note.title == 'Sin titulo' ? '' : note.title;
      _bodyController.text = note.isChecklist || note.preview == 'Sin contenido'
          ? ''
          : note.preview;
      _setChecklistItems(note.checklistItems);
      _imageUrls
        ..clear()
        ..addAll(note.imageUrls);

      final defaultFolder = await _defaultFolder();

      setState(() {
        _folderId = note.folderId ?? defaultFolder?.id;
        _folder = note.folderId == null
            ? defaultFolder?.name ?? 'Personal'
            : note.folder;
        _isPinned = note.isPinned;
        _isChecklist = note.isChecklist;
      });
    } catch (_) {
      setState(() {
        _message = 'No se pudo cargar la nota.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Sin titulo'
        : _titleController.text.trim();
    final body = _bodyController.text.trim();
    final checklistItems = _checklistItemsForSave();

    if (title == 'Sin titulo' &&
        body.isEmpty &&
        (!_isChecklist || checklistItems.isEmpty) &&
        _imageUrls.isEmpty &&
        _pendingImages.isEmpty) {
      setState(() {
        _message = 'Agrega un titulo o contenido para guardar.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final repository = ref.read(notesRepositoryProvider);

      if (_noteId == null) {
        _noteId = await repository.createNote(
          title: title,
          body: body,
          isPinned: _isPinned,
          folderId: await _resolvedFolderId(),
          folderName: _folder,
          isChecklist: _isChecklist,
          checklistItems: checklistItems,
          imageUrls: _imageUrls,
          syncImages: _didChangeImages || _imageUrls.isNotEmpty,
        );
      } else {
        await repository.updateNote(
          id: _noteId!,
          title: title,
          body: body,
          isPinned: _isPinned,
          folderId: await _resolvedFolderId(),
          folderName: _folder,
          isChecklist: _isChecklist,
          checklistItems: checklistItems,
          imageUrls: _imageUrls,
          syncImages: _didChangeImages || _imageUrls.isNotEmpty,
        );
      }

      final noteId = _noteId;
      if (noteId != null && _pendingImages.isNotEmpty) {
        final uploadedUrls = await repository.uploadNoteImages(
          noteId: noteId,
          images: _pendingImages,
        );
        _imageUrls.addAll(uploadedUrls);
        _pendingImages.clear();

        await repository.updateNote(
          id: noteId,
          title: title,
          body: body,
          isPinned: _isPinned,
          folderId: await _resolvedFolderId(),
          folderName: _folder,
          isChecklist: _isChecklist,
          checklistItems: checklistItems,
          imageUrls: _imageUrls,
          syncImages: true,
        );
      }

      ref.invalidate(notesProvider);

      if (mounted) {
        setState(() => _didChangeImages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota guardada.')),
        );
        context.go('/home');
      }
    } catch (error) {
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedNewDraft()) {
      context.pop();
      return;
    }

    final shouldDiscard = await _confirmDiscardNewDraft();
    if (shouldDiscard && mounted) {
      context.pop();
    }
  }

  bool _hasUnsavedNewDraft() {
    if (_isExistingNote || _isSaving) {
      return false;
    }

    final hasText =
        _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty;
    final hasChecklist = _checklistItems.any(
      (item) => item.controller.text.trim().isNotEmpty,
    );

    return hasText || hasChecklist || _pendingImages.isNotEmpty;
  }

  Future<bool> _confirmDiscardNewDraft() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.16),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
          ),
        ),
        title: const Text('Salir sin guardar?'),
        content: const Text(
          'Esta nota nueva todavia no se guardo.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => dialogContext.pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Descartar'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => dialogContext.pop(false),
              child: const Text('Seguir editando'),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _toggleChecklistMode() {
    setState(() {
      _isChecklist = !_isChecklist;
      if (_isChecklist && _checklistItems.isEmpty) {
        _checklistItems.add(_ChecklistDraft());
      }
    });
  }

  void _addChecklistItem() {
    setState(() => _checklistItems.add(_ChecklistDraft()));
  }

  void _addChecklistItemFromToolbar() {
    if (!_isChecklist) {
      setState(() {
        _isChecklist = true;
        if (_bodyController.text.trim().isNotEmpty) {
          _checklistItems.add(
            _ChecklistDraft(label: _bodyController.text.trim()),
          );
          _bodyController.clear();
        } else {
          _checklistItems.add(_ChecklistDraft());
        }
      });
      return;
    }

    _addChecklistItem();
  }

  void _switchToTextMode() {
    if (!_isChecklist) {
      setState(() {
        _message = 'Ya estas escribiendo una nota de texto.';
        _messageIsError = false;
      });
      return;
    }

    setState(() => _isChecklist = false);
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (images.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _pendingImages.addAll(images);
        _didChangeImages = true;
        _messageIsError = false;
        _message = '${images.length} imagen(es) lista(s) para guardar.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudieron seleccionar imagenes.';
          _messageIsError = true;
        });
      }
    }
  }

  void _removeImageUrl(String url) {
    setState(() {
      _imageUrls.remove(url);
      _didChangeImages = true;
    });
  }

  void _removePendingImage(XFile image) {
    setState(() {
      _pendingImages.remove(image);
      _didChangeImages = true;
    });
  }

  void _cycleBodyTextAlign() {
    setState(() {
      _bodyTextAlign = switch (_bodyTextAlign) {
        TextAlign.left => TextAlign.center,
        TextAlign.center => TextAlign.right,
        _ => TextAlign.left,
      };
    });
  }

  IconData _textAlignIcon() {
    return switch (_bodyTextAlign) {
      TextAlign.center => Icons.format_align_center_rounded,
      TextAlign.right => Icons.format_align_right_rounded,
      _ => Icons.format_align_left_rounded,
    };
  }

  void _setChecklistItems(List<ChecklistItem> items) {
    for (final item in _checklistItems) {
      item.dispose();
    }
    _checklistItems.clear();

    for (final item in items) {
      _checklistItems.add(
        _ChecklistDraft(label: item.label, isDone: item.isDone),
      );
    }
  }

  List<ChecklistItem> _checklistItemsForSave() {
    return _checklistItems
        .map(
          (item) => ChecklistItem(
            label: item.controller.text,
            isDone: item.isDone,
          ),
        )
        .where((item) => item.label.trim().isNotEmpty)
        .toList();
  }

  Future<void> _togglePin() async {
    final nextValue = !_isPinned;
    setState(() {
      _isPinned = nextValue;
      _message = nextValue ? 'Nota fijada.' : 'Nota desfijada.';
      _messageIsError = false;
    });

    final id = _noteId;
    if (id == null) {
      return;
    }

    try {
      await ref
          .read(notesRepositoryProvider)
          .updatePin(id: id, isPinned: nextValue);
      ref.invalidate(notesProvider);
    } catch (error) {
      setState(() {
        _isPinned = !nextValue;
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    }
  }

  void _selectFolder(Folder folder) {
    setState(() {
      _folderId = folder.id;
      _folder = folder.name;
    });
  }

  Future<String?> _resolvedFolderId() async {
    if (_folderId != null && _isUuid(_folderId!)) {
      return _folderId;
    }

    final folders = await _realFolders();
    for (final folder in folders) {
      if (folder.name == _folder) {
        return folder.id;
      }
    }

    for (final folder in folders) {
      if (folder.name == 'Personal') {
        return folder.id;
      }
    }

    return folders.isEmpty ? null : folders.first.id;
  }

  Future<Folder?> _defaultFolder() async {
    final folders = await _realFolders();

    for (final folder in folders) {
      if (folder.name == 'Personal') {
        return folder;
      }
    }

    return folders.isEmpty ? null : folders.first;
  }

  Future<List<Folder>> _realFolders() async {
    final cachedFolders = ref.read(foldersProvider).value;
    if (cachedFolders != null &&
        (!AppConfig.hasSupabaseConfig ||
            cachedFolders.every((folder) => _isUuid(folder.id)))) {
      return cachedFolders;
    }

    return ref.read(notesRepositoryProvider).fetchFolders();
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  Future<void> _deleteNote() async {
    final id = _noteId;
    if (id == null) {
      return;
    }

    try {
      await ref.read(notesRepositoryProvider).deleteNote(id);
      ref.invalidate(notesProvider);
      ref.invalidate(deletedNotesProvider);

      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
      });
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final title = _titleController.text.trim().isEmpty
        ? 'esta nota'
        : '"${_titleController.text.trim()}"';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.16),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
          ),
        ),
        title: const Text('Eliminar esta nota?'),
        content: Text(
          'Se movera $title a la papelera. Puedes restaurarla despues.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                dialogContext.pop();
                _deleteNote();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Mover a papelera'),
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

  String _friendlyError(Object error) {
    if (error is StateError) {
      return error.message;
    }

    if (error is PostgrestException) {
      if (error.message.contains('image_urls')) {
        return 'Falta configurar imagenes en Supabase. Ejecuta setup_note_images.sql en el proyecto correcto.';
      }

      return error.message;
    }

    if (error is AuthException) {
      return error.message;
    }

    final text = error.toString();
    if (text.contains('image_urls')) {
      return 'Falta configurar imagenes en Supabase. Ejecuta setup_note_images.sql en el proyecto correcto.';
    }

    if (text.contains('note-images') || text.contains('bucket')) {
      return 'No se pudo subir la imagen. Revisa que el bucket note-images exista y tenga politicas de Storage.';
    }

    if (text.contains('row-level security') || text.contains('policy')) {
      return 'Supabase bloqueo la subida por politicas RLS. Revisa las politicas del bucket note-images.';
    }

    if (text.contains('JWT') || text.contains('auth')) {
      return 'Tu sesion no esta activa. Inicia sesion de nuevo.';
    }

    return text.replaceFirst('Exception: ', '');
  }
}

class _ImagePreviewStrip extends StatelessWidget {
  const _ImagePreviewStrip({
    required this.imageUrls,
    required this.pendingImages,
    required this.onRemoveUrl,
    required this.onRemovePending,
  });

  final List<String> imageUrls;
  final List<XFile> pendingImages;
  final ValueChanged<String> onRemoveUrl;
  final ValueChanged<XFile> onRemovePending;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final url in imageUrls)
        _ImagePreviewTile(
          image: Image.network(url, fit: BoxFit.cover),
          onRemove: () => onRemoveUrl(url),
        ),
      for (final image in pendingImages)
        _ImagePreviewTile(
          image: Image.file(File(image.path), fit: BoxFit.cover),
          label: 'Nueva',
          onRemove: () => onRemovePending(image),
        ),
    ];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  const _ImagePreviewTile({
    required this.image,
    required this.onRemove,
    this.label,
  });

  final Widget image;
  final VoidCallback onRemove;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 128,
            height: 128,
            child: ColoredBox(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.nightSurface
                  : Colors.white,
              child: image,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton.filled(
            onPressed: onRemove,
            iconSize: 16,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.62),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        if (label != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      backgroundColor: AppColors.paperMuted,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChecklistDraft {
  _ChecklistDraft({String label = '', this.isDone = false})
    : controller = TextEditingController(text: label);

  final TextEditingController controller;
  bool isDone;

  void dispose() {
    controller.dispose();
  }
}

class _ChecklistEditor extends StatelessWidget {
  const _ChecklistEditor({
    required this.items,
    required this.onChanged,
    required this.onAdd,
  });

  final List<_ChecklistDraft> items;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in items.asMap().entries)
          _ChecklistEditorRow(
            item: entry.value,
            onChanged: onChanged,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Anadir elemento'),
          ),
        ),
      ],
    );
  }
}

class _ChecklistEditorRow extends StatelessWidget {
  const _ChecklistEditorRow({required this.item, required this.onChanged});

  final _ChecklistDraft item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isDone,
            onChanged: (value) {
              item.isDone = value ?? false;
              onChanged();
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: item.controller,
              onChanged: (_) => onChanged(),
              minLines: 1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Elemento',
                contentPadding: EdgeInsets.only(top: 12),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                decoration: item.isDone ? TextDecoration.lineThrough : null,
                color: item.isDone ? AppColors.inkMuted : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
