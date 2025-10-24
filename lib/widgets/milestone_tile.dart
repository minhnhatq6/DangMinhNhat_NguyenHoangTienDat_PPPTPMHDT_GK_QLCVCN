import 'package:flutter/material.dart';
import '../models/milestone.dart';
import 'package:intl/intl.dart';

class MilestoneTile extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MilestoneTile({
    Key? key,
    required this.milestone,
    required this.onTap,
    required this.onDelete,
    // --- THAY ĐỔI: Bỏ onToggleDone vì không còn trạng thái completed ---
    // final ValueChanged<bool> onToggleDone,
  }) : super(key: key);

  Color _parseColor(String? hex, BuildContext ctx) {
    if (hex == null || hex.isEmpty) return Theme.of(ctx).primaryColor;
    var s = hex.replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    try {
      final v = int.parse(s, radix: 16);
      return Color(v);
    } catch (_) {
      return Theme.of(ctx).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectColor = milestone.projectColors.isNotEmpty ? _parseColor(milestone.projectColors.first, context) : Colors.grey;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- THAY ĐỔI: Giao diện leading ---
              Icon(Icons.flag_circle, color: projectColor, size: 36),
              const SizedBox(width: 16),

              // --- THAY ĐỔI: Phần thông tin ở giữa ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (milestone.projectName != null && milestone.projectName!.isNotEmpty)
                      Text(
                        milestone.projectName!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // --- THAY ĐỔI: Phần bên phải ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (milestone.date != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(milestone.date!),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  SizedBox(
                    height: 24,
                    width: 30, // Tăng chiều rộng để dễ nhấn hơn
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (v) {
                        if (v == 'delete') {
                          onDelete();
                        } else if (v == 'edit') {
                          onTap();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Sửa')),
                        PopupMenuItem(value: 'delete', child: Text('Xóa')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}