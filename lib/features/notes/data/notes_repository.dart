import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/folder.dart';
import '../../../core/models/note.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).fetchNotes();
});

final foldersProvider = FutureProvider<List<Folder>>((ref) {
  return ref.watch(notesRepositoryProvider).fetchFolders();
});

final deletedNotesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).fetchDeletedNotes();
});

class NotesRepository {
  Future<List<Folder>> fetchFolders() async {
    if (!AppConfig.hasSupabaseConfig) {
      return mockFolders;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      return mockFolders;
    }

    final rows = await client
        .from('folders')
        .select('id, name, color, position')
        .eq('user_id', session.user.id)
        .order('position')
        .order('name');

    final folders = rows
        .whereType<Map<String, dynamic>>()
        .map(Folder.fromSupabase)
        .toList();

    return folders;
  }

  Future<List<Note>> fetchNotes() async {
    if (!AppConfig.hasSupabaseConfig) {
      return mockNotes;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      return mockNotes;
    }

    final rows = await client
        .from('notes')
        .select('*, note_items(*)')
        .isFilter('deleted_at', null)
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);
    final folderLookup = await _folderNameLookup(client, session.user.id);

    final notes = rows
        .whereType<Map<String, dynamic>>()
        .map((row) => Note.fromSupabase(_withFolderName(row, folderLookup)))
        .toList();

    return notes;
  }

  Future<List<Note>> fetchDeletedNotes() async {
    if (!AppConfig.hasSupabaseConfig) {
      return const [];
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      return const [];
    }

    final rows = await client
        .from('notes')
        .select('*, note_items(*)')
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    final folderLookup = await _folderNameLookup(client, session.user.id);

    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => Note.fromSupabase(_withFolderName(row, folderLookup)))
        .toList();
  }

  Future<Note?> fetchNoteById(String id) async {
    if (!AppConfig.hasSupabaseConfig) {
      for (final note in mockNotes) {
        if (note.id == id) {
          return note;
        }
      }
      return null;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      return null;
    }

    final row = await client
        .from('notes')
        .select('*, note_items(*)')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    final folderLookup = await _folderNameLookup(client, session.user.id);

    return row == null
        ? null
        : Note.fromSupabase(_withFolderName(row, folderLookup));
  }

  Future<String?> createNote({
    required String title,
    required String body,
    required bool isPinned,
    required String? folderId,
    required String folderName,
    bool isChecklist = false,
    List<ChecklistItem> checklistItems = const [],
    List<String> imageUrls = const [],
    bool syncImages = false,
  }) async {
    if (!AppConfig.hasSupabaseConfig) {
      return null;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      throw StateError('Necesitas iniciar sesion para guardar notas.');
    }

    final userId = session.user.id;
    final resolvedFolderId = await _resolveFolderId(
      client: client,
      userId: userId,
      folderId: folderId,
      folderName: folderName,
    );
    final values = {
      'user_id': userId,
      'folder_id': resolvedFolderId,
      'title': title.trim(),
      'body': isChecklist ? '' : body.trim(),
      'note_type': isChecklist ? 'checklist' : 'text',
      'is_pinned': isPinned,
    };
    // Keep image writes explicit so text-only saves still work before the
    // optional Storage migration is applied in a fresh Supabase project.
    if (syncImages) {
      values['image_urls'] = imageUrls;
    }

    final row = await client
        .from('notes')
        .insert(values)
        .select('id')
        .single();

    final noteId = row['id'] as String?;
    if (noteId != null && isChecklist) {
      await _replaceChecklistItems(client, noteId, checklistItems);
    }

    return noteId;
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
    required bool isPinned,
    required String? folderId,
    required String folderName,
    bool isChecklist = false,
    List<ChecklistItem> checklistItems = const [],
    List<String> imageUrls = const [],
    bool syncImages = false,
  }) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      throw StateError('Necesitas iniciar sesion para editar notas.');
    }

    final resolvedFolderId = await _resolveFolderId(
      client: client,
      userId: session.user.id,
      folderId: folderId,
      folderName: folderName,
    );

    final values = {
      'title': title.trim(),
      'body': isChecklist ? '' : body.trim(),
      'is_pinned': isPinned,
      'folder_id': resolvedFolderId,
      'note_type': isChecklist ? 'checklist' : 'text',
    };
    // See createNote: image_urls is synced only when image state changed.
    if (syncImages) {
      values['image_urls'] = imageUrls;
    }

    await client
        .from('notes')
        .update(values)
        .eq('id', id);

    await _replaceChecklistItems(
      client,
      id,
      isChecklist ? checklistItems : const [],
    );
  }

  Future<void> updatePin({required String id, required bool isPinned}) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      throw StateError('Necesitas iniciar sesion para fijar notas.');
    }

    await Supabase.instance.client
        .from('notes')
        .update({'is_pinned': isPinned})
        .eq('id', id);
  }

  Future<List<String>> uploadNoteImages({
    required String noteId,
    required List<XFile> images,
  }) async {
    if (!AppConfig.hasSupabaseConfig || images.isEmpty) {
      return const [];
    }

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      throw StateError('Necesitas iniciar sesion para subir imagenes.');
    }

    final uploadedUrls = <String>[];
    final userId = session.user.id;
    final storage = client.storage.from('note-images');

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final extension = _fileExtension(image.name);
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final path = '$userId/$noteId/$fileName';

      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentType(extension),
          upsert: false,
        ),
      );
      uploadedUrls.add(storage.getPublicUrl(path));
    }

    return uploadedUrls;
  }

  Future<void> deleteNote(String id) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      throw StateError('Necesitas iniciar sesion para eliminar notas.');
    }

    await Supabase.instance.client
        .from('notes')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<void> restoreNote(String id) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      throw StateError('Necesitas iniciar sesion para restaurar notas.');
    }

    await Supabase.instance.client
        .from('notes')
        .update({'deleted_at': null})
        .eq('id', id);
  }

  Future<void> permanentlyDeleteNote(String id) async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    if (Supabase.instance.client.auth.currentSession == null) {
      throw StateError('Necesitas iniciar sesion para eliminar notas.');
    }

    await Supabase.instance.client.from('notes').delete().eq('id', id);
  }

  Future<String?> _resolveFolderId({
    required SupabaseClient client,
    required String userId,
    required String? folderId,
    required String folderName,
  }) async {
    if (folderId != null && _isUuid(folderId)) {
      return folderId;
    }

    final selected = await _folderIdByName(client, userId, folderName);
    if (selected != null) {
      return selected;
    }

    return _folderIdByName(client, userId, 'Personal');
  }

  Future<String?> _folderIdByName(
    SupabaseClient client,
    String userId,
    String name,
  ) async {
    final row = await client
        .from('folders')
        .select('id')
        .eq('user_id', userId)
        .eq('name', name)
        .limit(1)
        .maybeSingle();

    return row?['id'] as String?;
  }

  Future<Map<String, String>> _folderNameLookup(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = await client
        .from('folders')
        .select('id, name')
        .eq('user_id', userId);

    return {
      for (final row in rows.whereType<Map<String, dynamic>>())
        if (row['id'] is String && row['name'] is String)
          row['id'] as String: row['name'] as String,
    };
  }

  Map<String, dynamic> _withFolderName(
    Map<String, dynamic> row,
    Map<String, String> folderLookup,
  ) {
    final folderId = row['folder_id'];
    final folderName = folderId is String ? folderLookup[folderId] : null;

    if (folderName == null) {
      return row;
    }

    return {
      ...row,
      'folder': {'name': folderName},
    };
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _fileExtension(String name) {
    final parts = name.toLowerCase().split('.');
    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last;
    return switch (extension) {
      'png' || 'webp' || 'gif' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _replaceChecklistItems(
    SupabaseClient client,
    String noteId,
    List<ChecklistItem> items,
  ) async {
    await client.from('note_items').delete().eq('note_id', noteId);

    final rows = items
        .asMap()
        .entries
        .where((entry) => entry.value.label.trim().isNotEmpty)
        .map(
          (entry) => {
            'note_id': noteId,
            'content': entry.value.label.trim(),
            'is_done': entry.value.isDone,
            'position': entry.key,
          },
        )
        .toList();

    if (rows.isNotEmpty) {
      await client.from('note_items').insert(rows);
    }
  }
}

const mockFolders = [
  Folder(id: 'trabajo', name: 'Trabajo', color: '#8A9A7C', position: 1),
  Folder(id: 'personal', name: 'Personal', color: '#C29A7E', position: 2),
  Folder(id: 'ideas', name: 'Ideas', color: '#A98DAF', position: 3),
];
