import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/projects_provider.dart';
import '../models/projects.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({Key? key}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    if (provider.projects.isEmpty) {
      Future.microtask(() => provider.loadProjects());
    }
  }

  Future<void> _showAddProjectDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<Color> tempColors = [Colors.blue];
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tạo Project Mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên project')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Màu sắc:', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tempColors.map((color) => Chip(
                        label: Text(_colorToHex(color), style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)),
                        backgroundColor: color,
                        onDeleted: tempColors.length > 1 ? () => setStateDialog(() => tempColors.remove(color)) : null,
                        deleteIconColor: color.computeLuminance() > 0.5 ? Colors.black45 : Colors.white70,
                      )),
                      ActionChip(
                        label: const Icon(Icons.add, size: 18),
                        onPressed: () async {
                          final sel = await _pickColorDialog(tempColors.last);
                          if (sel != null && !tempColors.contains(sel)) {
                            setStateDialog(() => tempColors.add(sel));
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên project là bắt buộc')));
                    return;
                  }
                  try {
                    await provider.addProject(
                      nameCtrl.text.trim(),
                      desc: descCtrl.text.trim(),
                      colors: tempColors.map(_colorToHex).toList(),
                    );
                    Navigator.pop(ctx, true);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: const Text('Tạo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditProjectDialog(Project project) async {
    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description);
    List<Color> tempColors = project.colors.map((hex) => _parseColor(hex, fallback: Colors.blue)).toList();
    if (tempColors.isEmpty) tempColors.add(Colors.blue);
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Sửa Project', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên project')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Màu sắc:', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tempColors.map((color) => Chip(
                        label: Text(_colorToHex(color), style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)),
                        backgroundColor: color,
                        onDeleted: tempColors.length > 1 ? () => setStateDialog(() => tempColors.remove(color)) : null,
                        deleteIconColor: color.computeLuminance() > 0.5 ? Colors.black45 : Colors.white70,
                      )),
                      ActionChip(
                        label: const Icon(Icons.add, size: 18),
                        onPressed: () async {
                          final sel = await _pickColorDialog(tempColors.last);
                          if (sel != null && !tempColors.contains(sel)) {
                            setStateDialog(() => tempColors.add(sel));
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    await provider.updateProject(
                      project.id,
                      name: nameCtrl.text.trim(),
                      desc: descCtrl.text.trim(),
                      colors: tempColors.map(_colorToHex).toList(),
                    );
                    Navigator.pop(ctx, true);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Project project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa project "${project.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await Provider.of<ProjectProvider>(context, listen: false).deleteProject(project.id);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Color _parseColor(String? hex, {Color fallback = Colors.blue}) {
    if (hex == null) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    try { return Color(int.parse(s, radix: 16)); } catch (_) { return fallback; }
  }

  String _colorToHex(Color c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Future<Color?> _pickColorDialog(Color initialColor) {
    Color pickerColor = initialColor;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chọn màu'),
        content: SingleChildScrollView(child: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: (c) => pickerColor = c,
          enableAlpha: false,
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, pickerColor), child: const Text('Chọn')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    return Scaffold(
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => provider.loadProjects(),
        child: provider.projects.isEmpty
            ? Center(
          child: Text("Chưa có dự án nào.\nHãy nhấn '+' để tạo mới!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8).copyWith(bottom: 90),
          itemCount: provider.projects.length,
          itemBuilder: (ctx, i) {
            final p = provider.projects[i];
            final displayColor = p.colors.isNotEmpty ? _parseColor(p.colors.first) : Colors.grey;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: displayColor,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: p.description != null && p.description!.isNotEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(p.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
                )
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _showEditProjectDialog(p);
                    if (value == 'delete') _showDeleteConfirmDialog(p);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Sửa')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline), SizedBox(width: 8), Text('Xóa')])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        icon: const Icon(Icons.add),
        label: const Text("Tạo Dự án"),
      ),
    );
  }
}