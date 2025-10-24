import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/milestone_provider.dart';
import '../models/milestone.dart';
import '../widgets/add_edit_milestone_dialog.dart';
import '../providers/projects_provider.dart';

class MilestonePage extends StatefulWidget {
  const MilestonePage({Key? key}) : super(key: key);

  @override
  State<MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends State<MilestonePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MilestoneProvider>(context, listen: false).loadMilestones();
      Provider.of<ProjectProvider>(context, listen: false).loadProjects();
    });
  }

  Future<void> _openAddEditDialog({Milestone? milestone}) async {
    final milestoneProv = Provider.of<MilestoneProvider>(context, listen: false);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddEditMilestoneDialog(milestone: milestone),
    );

    if (result != null) {
      try {
        if (milestone == null) {
          final newMilestone = Milestone(
            id: '', name: result['name'], description: result['description'],
            projectId: result['projectId'], date: result['date'],
          );
          await milestoneProv.addMilestone(newMilestone);
        } else {
          await milestoneProv.updateMilestone(milestone.id, {
            'name': result['name'], 'description': result['description'],
            'projectId': result['projectId'], 'date': result['date']?.toIso8601String(),
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thao tác thất bại: $e')));
        }
      }
    }
  }

  Color _parseColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    try { return Color(int.parse(s, radix: 16)); } catch (_) { return fallback; }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MilestoneProvider>(context);

    return Scaffold(
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.milestones.isEmpty
          ? const Center(child: Text('Chưa có cột mốc nào.'))
          : RefreshIndicator(
        onRefresh: () => prov.loadMilestones(),
        child: ListView.builder(
          padding: const EdgeInsets.all(8).copyWith(bottom: 90),
          itemCount: prov.milestones.length,
          itemBuilder: (ctx, i) {
            final m = prov.milestones[i];
            final projectColor = m.projectColors.isNotEmpty ? _parseColor(m.projectColors.first) : Colors.grey;

            // --- CẤU TRÚC ĐÚNG ĐỂ TRÁNH OVERFLOW ---
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _openAddEditDialog(milestone: m),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.flag_circle, color: projectColor, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(m.projectName ?? 'Không có dự án', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (m.date != null)
                            Text(DateFormat('dd/MM/yyyy').format(m.date!), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _openAddEditDialog(milestone: m);
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xác nhận'),
                                      content: Text('Bạn có muốn xóa cột mốc "${m.name}" không?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await prov.deleteMilestone(m.id);
                                    } catch (e) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
                                    }
                                  }
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
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Tạo Cột mốc',
      ),
    );
  }
}