// lib/widgets/add_edit_milestone_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/milestone.dart';
import '../providers/projects_provider.dart';

class AddEditMilestoneDialog extends StatefulWidget {
  final Milestone? milestone;
  const AddEditMilestoneDialog({Key? key, this.milestone}) : super(key: key);

  @override
  State<AddEditMilestoneDialog> createState() => _AddEditMilestoneDialogState();
}

class _AddEditMilestoneDialogState extends State<AddEditMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  DateTime? _date;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    final m = widget.milestone;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _date = m?.date;
    _projectId = m?.projectId;

    // Không cần tải lại project ở đây, vì trang cha đã tải rồi
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _date = DateTime.utc(date.year, date.month, date.day));
    }
  }

  String _formatDate(DateTime? d) => d == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để đảm bảo dropdown được cập nhật
    return Consumer<ProjectProvider>(
      builder: (context, pp, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(widget.milestone == null ? 'Tạo Cột mốc' : 'Sửa Cột mốc'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên cột mốc'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _projectId,
                    decoration: const InputDecoration(labelText: 'Thuộc Dự án'),
                    items: pp.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) => setState(() => _projectId = v),
                    validator: (v) => v == null ? 'Vui lòng chọn dự án' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Ngày: ${_formatDate(_date)}')),
                      TextButton(onPressed: () => _pickDate(context), child: const Text('Chọn')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'description': _descCtrl.text.trim(),
                  'date': _date,
                  'projectId': _projectId,
                });
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}