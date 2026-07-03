import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFB7B0A5) : AppColors.inkMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasImage = note.imageUrls.isNotEmpty;
        final compactImage = hasImage && constraints.maxHeight < 220;
        final imageHeight = compactImage ? 82.0 : 104.0;
        final previewLines = hasImage ? 1 : 4;
        final checklistLimit = hasImage ? 1 : 4;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push(
            note.id == null ? '/editor' : '/editor?id=${note.id}',
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(compactImage ? 12 : 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurface : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: double.infinity,
                      height: imageHeight,
                      child: Image.network(
                        note.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AppColors.sage.withValues(alpha: 0.16),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compactImage ? 8 : 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        maxLines: hasImage ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (note.isPinned)
                      const Icon(Icons.push_pin_rounded, size: 15),
                  ],
                ),
                SizedBox(height: compactImage ? 5 : 8),
                if (note.checklistItems.isNotEmpty)
                  ...note.checklistItems.take(checklistLimit).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.isDone
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: item.isDone ? AppColors.sage : muted,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isDone
                                    ? muted
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    note.preview,
                    maxLines: previewLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const Spacer(),
                Text(
                  '${note.folder} - ${note.dateLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note.reminderLabel != null && !compactImage) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(
                        alpha: isDark ? 0.25 : 0.16,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            note.reminderLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
