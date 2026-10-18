class Folder {
  factory Folder.fromSupabase(Map<String, dynamic> row) {
    return Folder(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? 'Notas',
      color: row['color'] as String?,
      position: row['position'] as int? ?? 0,
    );
  }
  const Folder({
    required this.id,
    required this.name,
    this.color,
    this.position = 0,
  });

  final String id;
  final String name;
  final String? color;
  final int position;
}
