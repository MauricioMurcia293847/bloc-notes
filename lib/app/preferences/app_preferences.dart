import 'package:flutter_riverpod/flutter_riverpod.dart';

final textSizeProvider = NotifierProvider<TextSizeController, AppTextSize>(
  TextSizeController.new,
);

final notesSortProvider = NotifierProvider<NotesSortController, NotesSortOrder>(
  NotesSortController.new,
);

final notesViewModeProvider = NotifierProvider<NotesViewModeController, NotesViewMode>(
  NotesViewModeController.new,
);

enum AppTextSize {
  small('Pequeno', 0.94),
  medium('Mediano', 1),
  large('Grande', 1.12);

  const AppTextSize(this.label, this.scale);

  final String label;
  final double scale;
}

class TextSizeController extends Notifier<AppTextSize> {
  @override
  AppTextSize build() => AppTextSize.medium;

  void setSize(AppTextSize size) {
    state = size;
  }
}

enum NotesSortOrder {
  recent('Recientes'),
  title('Titulo'),
  folder('Carpeta');

  const NotesSortOrder(this.label);

  final String label;
}

class NotesSortController extends Notifier<NotesSortOrder> {
  @override
  NotesSortOrder build() => NotesSortOrder.recent;

  void setOrder(NotesSortOrder order) {
    state = order;
  }
}

enum NotesViewMode {
  grid,
  list,
}

class NotesViewModeController extends Notifier<NotesViewMode> {
  @override
  NotesViewMode build() => NotesViewMode.grid;

  void setMode(NotesViewMode mode) {
    state = mode;
  }
}
