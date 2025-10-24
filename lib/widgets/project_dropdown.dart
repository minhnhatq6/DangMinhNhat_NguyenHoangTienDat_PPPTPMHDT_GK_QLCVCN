import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// THAY ĐỔI 1: Import ProjectProvider thay vì TaskProvider
import '../providers/projects_provider.dart';

class ProjectDropdown extends StatefulWidget {
  final String? initialProjectId;
  // THÊM 2: Thêm một callback để thông báo cho widget cha khi có thay đổi
  final Function(String?)? onChanged;

  const ProjectDropdown({
    super.key,
    this.initialProjectId,
    this.onChanged, // Thêm vào constructor
  });

  @override
  State<ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends State<ProjectDropdown> {
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    // Tải project nếu cần
    Future.microtask(() => Provider.of<ProjectProvider>(context, listen: false).loadProjects());
  }

  // Hàm tiện ích để parse màu
  Color _parseColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    try {
      final v = int.parse(s, radix: 16);
      return Color(v);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    // THAY ĐỔI 3: Sử dụng ProjectProvider
    final projectProv = Provider.of<ProjectProvider>(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField2<String>(
          value: _selectedProjectId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Chọn Project",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("Tất cả Project"),
                ],
              ),
            ),
            // THAY ĐỔI 4: Lặp qua `projectProv.projects` và hiển thị màu sắc
            ...projectProv.projects.map((p) {
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
                    Text(
                      p.name.isNotEmpty ? p.name : "Không tên",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProjectId = value;
            });
            // Gọi callback để thông báo cho widget cha
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          dropdownStyleData: DropdownStyleData(
            maxHeight: 250,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor, // Sử dụng màu của theme
            ),
            elevation: 6,
          ),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12),
          ),
          iconStyleData: IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ),
    );
  }
}