class Note {
  const Note({
    this.id,
    this.folderId,
    required this.title,
    required this.preview,
    required this.folder,
    required this.dateLabel,
    this.reminderLabel,
    this.isPinned = false,
    this.isChecklist = false,
    this.checklistItems = const [],
    this.imageUrls = const [],
  });

  final String? id;
  final String? folderId;
  final String title;
  final String preview;
  final String folder;
  final String dateLabel;
  final String? reminderLabel;
  final bool isPinned;
  final bool isChecklist;
  final List<ChecklistItem> checklistItems;
  final List<String> imageUrls;

  factory Note.fromSupabase(Map<String, dynamic> row) {
    final folder = row['folder'] ?? row['folders'];
    final folderId = row['folder_id'] as String?;
    final rawItems = row['note_items'];

    return Note(
      id: row['id'] as String?,
      folderId: folderId,
      title: (row['title'] as String?)?.trim().isNotEmpty == true
          ? row['title'] as String
          : 'Sin titulo',
      preview: (row['body'] as String?)?.trim().isNotEmpty == true
          ? row['body'] as String
          : 'Sin contenido',
      folder: _folderName(folder, folderId: folderId),
      dateLabel: _formatDateLabel(row['updated_at'] as String?),
      reminderLabel: row['reminder_at'] == null ? null : 'Recordatorio',
      isPinned: row['is_pinned'] as bool? ?? false,
      isChecklist: row['note_type'] == 'checklist',
      checklistItems: rawItems is List
          ? (rawItems
                  .whereType<Map<String, dynamic>>()
                  .map(ChecklistItem.fromSupabase)
                  .toList()
                ..sort((a, b) => a.position.compareTo(b.position)))
          : const [],
      imageUrls: _imageUrls(row['image_urls']),
    );
  }
}

List<String> _imageUrls(Object? value) {
  if (value is List) {
    return value.whereType<String>().where((url) => url.isNotEmpty).toList();
  }

  return const [];
}

String _folderName(Object? folder, {String? folderId}) {
  if (folder is Map<String, dynamic>) {
    return folder['name'] as String? ?? 'Notas';
  }

  if (folder is List && folder.isNotEmpty) {
    final firstFolder = folder.first;
    if (firstFolder is Map<String, dynamic>) {
      return firstFolder['name'] as String? ?? 'Notas';
    }
  }

  if (folderId != null && folderId.isNotEmpty) {
    return 'Personal';
  }

  return 'Notas';
}

class ChecklistItem {
  const ChecklistItem({
    this.id,
    required this.label,
    this.isDone = false,
    this.position = 0,
  });

  final String? id;
  final String label;
  final bool isDone;
  final int position;

  factory ChecklistItem.fromSupabase(Map<String, dynamic> row) {
    return ChecklistItem(
      id: row['id'] as String?,
      label: row['content'] as String? ?? '',
      isDone: row['is_done'] as bool? ?? false,
      position: row['position'] as int? ?? 0,
    );
  }
}

String _formatDateLabel(String? value) {
  if (value == null) {
    return 'Hoy';
  }

  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) {
    return 'Hoy';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final noteDay = DateTime(date.year, date.month, date.day);

  if (noteDay == today) {
    return 'Hoy';
  }

  return '${date.day}/${date.month}';
}

const mockNotes = [
  Note(
    title: 'Lista del super',
    preview: 'Leche, cafe, aguacates y huevos.',
    folder: 'Personal',
    dateLabel: '12 jun',
    reminderLabel: 'Manana 9:00',
    isPinned: true,
    checklistItems: [
      ChecklistItem(label: 'Leche de avena', isDone: true),
      ChecklistItem(label: 'Cafe'),
      ChecklistItem(label: 'Aguacates'),
    ],
  ),
  Note(
    title: 'Reunion equipo',
    preview: 'Revisar roadmap del Q3 y asignar responsables de cada entrega.',
    folder: 'Trabajo',
    dateLabel: 'Hoy',
    reminderLabel: 'Manana 9:00',
    isPinned: true,
  ),
  Note(
    title: 'Ideas de regalo',
    preview:
        'Para el cumple de Ana: libro de ceramica, plantas, una buena taza.',
    folder: 'Ideas',
    dateLabel: '12 jun',
  ),
  Note(
    title: 'Frase del dia',
    preview: '"La calma es la cuna del poder." Josiah G. Holland',
    folder: 'Personal',
    dateLabel: '10 jun',
  ),
];
