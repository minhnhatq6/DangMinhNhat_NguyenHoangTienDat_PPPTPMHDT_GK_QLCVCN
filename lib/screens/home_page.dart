import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/projects_provider.dart';
import 'auth/login_screen.dart';
import '../widgets/task_tile.dart';
import '../models/task.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../providers/theme_provider.dart';
import 'calendar_page.dart';
import 'milestone_page.dart';
import '../screens/projects_page.dart'; // Đổi tên import nếu cần

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _search = '';
  String _statusFilter = 'all';
  int? _priorityFilter;
  String? _projectFilter;

  @override
  void initState() {
    super.initState();
    final projectProv = Provider.of<ProjectProvider>(context, listen: false);
    final taskProv = Provider.of<TaskProvider>(context, listen: false);

    Future.microtask(() async {
      await projectProv.loadProjects();
      await taskProv.loadTasks();
      await taskProv.loadStats();
    });
  }

  Future<void> _openAddDialog() async {
    final res = await showDialog(context: context, builder: (_) => const AddEditTaskDialog());
    if (res != null && res is Map) {
      final newTask = Task(
        id: '',
        title: res['title'],
        note: res['note'],
        dueDate: res['dueDate'],
        priority: res['priority'] ?? 1,
        projectId: res['projectId'],
        projectName: null,
        category: res['category'] ?? '',
        progress: res['progress'] ?? 0,
      );
      await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
    }
  }

  void _applyFilters() {
    final filters = <String, String>{};
    if (_search.isNotEmpty) filters['search'] = _search;
    if (_statusFilter != 'all') filters['status'] = _statusFilter;
    if (_priorityFilter != null) filters['priority'] = _priorityFilter.toString();
    if (_projectFilter != null) filters['projectId'] = _projectFilter!;
    Provider.of<TaskProvider>(context, listen: false).loadTasks(filters: filters);
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

  Widget _buildTaskPage() {
    final projectProv = Provider.of<ProjectProvider>(context);
    final taskProv = Provider.of<TaskProvider>(context);
    final tasks = _projectFilter == null ? taskProv.tasks : taskProv.tasks.where((t) => t.projectId?.toString() == _projectFilter).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm công việc...'),
              onChanged: (v) {
                _search = v;
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'all' || v == 'pending' || v == 'done') _statusFilter = v;
              if (v == 'pall') _priorityFilter = null;
              if (v == 'phigh') _priorityFilter = 2;
              if (v == 'pnorm') _priorityFilter = 1;
              if (v == 'plow') _priorityFilter = 0;
              _applyFilters();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'pending', child: Text('Chưa hoàn thành')),
              const PopupMenuItem(value: 'done', child: Text('Đã hoàn thành')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pall', child: Text('Mức ưu tiên: Tất cả')),
              const PopupMenuItem(value: 'phigh', child: Text('Ưu tiên: Cao')),
              const PopupMenuItem(value: 'pnorm', child: Text('Ưu tiên: Bình thường')),
              const PopupMenuItem(value: 'plow', child: Text('Ưu tiên: Thấp')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: _projectFilter,
            hint: const Text("Dự án"),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text("Tất cả dự án")),
              ...projectProv.projects.map((p) {
                final color = p.colors.isNotEmpty ? _parseColor(p.colors.first) : Colors.grey;
                return DropdownMenuItem<String?>(
                  value: p.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(p.name.isNotEmpty ? p.name : 'Không tên'),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() => _projectFilter = value);
              _applyFilters();
            },
          ),
        ]),
      ),
      Expanded(
        child: taskProv.loading
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
            ? const Center(child: Text('Không có công việc'))
            : RefreshIndicator(
          onRefresh: () => taskProv.loadTasks(),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, i) {
              final t = tasks[i];
              return TaskTile(
                task: t,
                onToggleDone: () async => await taskProv.completeTask(t, !t.isDone),
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xác nhận'),
                      content: const Text('Bạn có muốn xóa công việc này?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                      ],
                    ),
                  );
                  if (ok == true) await taskProv.deleteTask(t.id);
                },
                onTap: () async {
                  final res = await showDialog(context: context, builder: (_) => AddEditTaskDialog(task: t));
                  if (res != null && res is Map) {
                    t.title = res['title'];
                    t.note = res['note'];
                    t.dueDate = res['dueDate'];
                    t.priority = res['priority'] ?? t.priority;
                    t.category = res['category'] ?? t.category;
                    t.projectId = res['projectId'] ?? t.projectId;
                    t.progress = res['progress'] ?? t.progress;
                    await taskProv.updateTask(t);
                  }
                },
              );
            },
          ),
        ),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    final pages = [
      _buildTaskPage(),
      const CalendarPage(),
      const MilestonePage(),
      const ProjectPage(),
    ];

   return Scaffold(
      appBar: AppBar(
        title: Text('Tasks - ${auth.user?['displayName'] ?? ''}'),
        actions: [
          IconButton(icon: Icon(themeProv.isDark ? Icons.brightness_2_outlined : Icons.wb_sunny_outlined), onPressed: () => themeProv.toggle()),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              // Xóa dữ liệu providers khi logout
              Provider.of<TaskProvider>(context, listen: false).tasks.clear();
              Provider.of<ProjectProvider>(context, listen: false).projects.clear();
              // ...
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      // Sử dụng LayoutBuilder để chọn giao diện phù hợp
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Nếu chiều rộng màn hình lớn hơn 600px (ngưỡng cho tablet/web)
          if (constraints.maxWidth > 600) {
            // Hiển thị giao diện Web với NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all, // Hiển thị cả icon và text
                  leading: FloatingActionButton(
                    elevation: 0,
                    onPressed: _openAddDialog,
                    child: const Icon(Icons.add),
                  ),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: Text('Công việc')),
                    NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Lịch')),
                    NavigationRailDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: Text('Cột mốc')),
                    NavigationRailDestination(icon: Icon(Icons.workspaces_outlined), selectedIcon: Icon(Icons.workspaces), label: Text('Dự án')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_currentIndex]),
              ],
            );
          } else {
            // Hiển thị giao diện Mobile với BottomNavigationBar
            return Scaffold(
              body: pages[_currentIndex],
              floatingActionButton: _currentIndex == 0
                  ? FloatingActionButton(onPressed: _openAddDialog, child: const Icon(Icons.add))
                  : null,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.task), label: "Công việc"),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Lịch"),
                  BottomNavigationBarItem(icon: Icon(Icons.flag), label: "Cột mốc"),
                  BottomNavigationBarItem(icon: Icon(Icons.workspaces), label: "Dự án"),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}