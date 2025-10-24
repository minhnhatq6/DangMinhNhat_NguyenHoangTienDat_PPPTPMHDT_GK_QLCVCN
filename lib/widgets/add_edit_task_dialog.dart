import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/task.dart';
import '../providers/projects_provider.dart';

class AddEditTaskDialog extends StatefulWidget {
  final Task? task;
  const AddEditTaskDialog({Key? key, this.task}) : super(key: key);

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;

  DateTime? _due;
  int _priority = 1;
  String _category = '';
  String? _projectId;
  int _progress = 0;

  // controllers cho create-project inline
  final _projNameCtrl = TextEditingController();
  final _projDescCtrl = TextEditingController();
  List<Color> _pickedColors = [Colors.blue];
  bool _creatingProject = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _due = t?.dueDate;
    _priority = t?.priority ?? 1;
    _category = t?.category ?? '';
    _projectId = t?.projectId;
    _progress = t?.progress ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).loadProjects();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _projNameCtrl.dispose();
    _projDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, DateTime? initial, Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

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

  // --- HÀM ĐÃ ĐƯỢC TỐI ƯU HÓA ---
  Future<void> _showCreateProjectDialog() async {
    _projNameCtrl.clear();
    _projDescCtrl.clear();
    List<Color> tempColors = [Colors.blue];
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          return AlertDialog(
            title: const Text('Tạo project mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _projNameCtrl, decoration: const InputDecoration(labelText: 'Tên project')),
                  const SizedBox(height: 8),
                  TextField(controller: _projDescCtrl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Màu sắc:', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tempColors.map((color) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black26)),
                          ),
                          InkWell(
                            onTap: () {
                              if (tempColors.length > 1) {
                                setStateDialog(() => tempColors.remove(color));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phải có ít nhất một màu')));
                              }
                            },
                            child: const Icon(Icons.cancel, color: Colors.red, size: 18),
                          )
                        ],
                      )),
                      GestureDetector(
                        onTap: () async {
                          final sel = await showDialog<Color>(
                            context: context,
                            builder: (ctx3) {
                              Color pickerColor = tempColors.last;
                              return AlertDialog(
                                title: const Text('Chọn màu'),
                                content: ColorPicker(
                                  pickerColor: pickerColor,
                                  onColorChanged: (c) => pickerColor = c,
                                  enableAlpha: false,
                                  pickerAreaHeightPercent: 0.8,
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx3), child: const Text('Huỷ')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx3, pickerColor), child: const Text('Chọn')),
                                ],
                              );
                            },
                          );
                          if (sel != null && !tempColors.contains(sel)) {
                            setStateDialog(() => tempColors.add(sel));
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
              ElevatedButton(
                onPressed: () {
                  if (_projNameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tên project')));
                    return;
                  }
                  _pickedColors = List.from(tempColors);
                  Navigator.pop(ctx, true);
                },
                child: const Text('Tạo'),
              ),
            ],
          );
        });
      },
    );

    if (ok == true) {
      setState(() => _creatingProject = true);
      try {
        final hexColors = _pickedColors.map(_colorToHex).toList();

        // 1. Gọi và chờ kết quả trả về là một Project object
        final newProject = await provider.addProject(
          _projNameCtrl.text.trim(),
          desc: _projDescCtrl.text.trim(),
          colors: hexColors,
        );

        // 2. XÓA BỎ LỆNH GỌI API KHÔNG CẦN THIẾT
        // await provider.loadProjects(); // <-- DÒNG NÀY ĐÃ ĐƯỢC XÓA

        // 3. Sử dụng trực tiếp project vừa nhận được để lấy ID
        setState(() => _projectId = newProject.id);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tạo project thất bại: $e')));
      } finally {
        setState(() => _creatingProject = false);
      }
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<ProjectProvider>(context);

    return AlertDialog(
      title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)')),
              const SizedBox(height: 12),
              _buildDateRow('Hạn chót', _due, (d) => setState(() => _due = d)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Ưu tiên'),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('Cao')),
                        DropdownMenuItem(value: 1, child: Text('Bình thường')),
                        DropdownMenuItem(value: 0, child: Text('Thấp')),
                      ],
                      onChanged: (v) => setState(() => _priority = v ?? 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pp.loading && _projectId == null) // Chỉ hiển thị loading khi đang tải lần đầu
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  children: [
                    DropdownButtonFormField<String?>(
                      value: _projectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Không chọn project')),
                        ...pp.projects.map((p) {
                          final color = p.colors.isNotEmpty ? _parseColor(p.colors.first) : Colors.grey;
                          return DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _projectId = v),
                      decoration: const InputDecoration(labelText: 'Project'),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: _creatingProject ? const Text('Đang tạo...') : const Text('Tạo project mới'),
                            onPressed: _creatingProject ? null : _showCreateProjectDialog,
                          ),
                        ),
                        if (pp.projects.isNotEmpty)
                          IconButton(
                            tooltip: 'Làm mới',
                            icon: const Icon(Icons.refresh),
                            onPressed: () => pp.loadProjects(),
                          ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Tiến độ:'),
                  Expanded(
                    child: Slider(
                      value: _progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_progress%',
                      onChanged: (v) => setState(() => _progress = v.toInt()),
                    ),
                  ),
                  Text('$_progress%'),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'title': _titleCtrl.text.trim(),
              'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              'dueDate': _due,
              'priority': _priority,
              'category': _category,
              'projectId': _projectId,
              'progress': _progress,
            });
          },
          child: const Text('Lưu'),
        )
      ],
    );
  }

  Widget _buildDateRow(String label, DateTime? date, Function(DateTime) onPicked) {
    return Row(
      children: [
        Expanded(
          child: Text(date == null ? '$label: chưa chọn' : '$label: ${DateFormat.yMd().add_jm().format(date)}'),
        ),
        TextButton(onPressed: () => _pickDate(context, date, onPicked), child: const Text('Chọn')),
      ],
    );
  }
}