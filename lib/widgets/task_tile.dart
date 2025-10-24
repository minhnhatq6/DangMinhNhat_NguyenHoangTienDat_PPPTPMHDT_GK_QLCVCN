import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleDone;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onToggleDone,
  }) : super(key: key);

  Color _parseColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    try {
      return Color(int.parse(s, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Widget _buildProjectChip() {
    if (task.projectName == null || task.projectName!.isEmpty) {
      return const SizedBox.shrink();
    }
    final color = task.projectColors.isNotEmpty ? _parseColor(task.projectColors.first) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            task.projectName!,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.isDone;

    Color priorityColor = Colors.transparent;
    if (!isDone) {
      if (task.priority == 2) priorityColor = theme.colorScheme.error.withOpacity(0.7);
      if (task.priority == 0) priorityColor = Colors.green.withOpacity(0.7);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: priorityColor,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.25,
                child: Checkbox(
                  value: isDone,
                  onChanged: (v) => onToggleDone(),
                  activeColor: theme.primaryColor,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey.shade600 : theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDone ? Colors.grey.shade500 : Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildProjectChip(),
                        if (task.dueDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: isDone ? Colors.grey : theme.colorScheme.secondary),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(task.dueDate!),
                                style: TextStyle(color: isDone ? Colors.grey : theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onTap();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Sửa')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline), SizedBox(width: 8), Text('Xóa')])),
                ],
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}