import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/projects.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> tasks = [];
  bool loading = false;
  Map<String, dynamic>? stats;

  List<Project> _projects = [];

  void updateProjects(List<Project> newProjects) {
    _projects = newProjects;
    if (tasks.isNotEmpty) {
      final projectMap = {for (var p in _projects) p.id: p};
      for (var task in tasks) {
        if (projectMap.containsKey(task.projectId)) {
          final project = projectMap[task.projectId]!;
          task.projectName = project.name;
          task.projectColors = project.colors;
        } else {
          task.projectName = null;
          task.projectColors = [];
        }
      }
      notifyListeners();
    }
  }

  Future<void> loadTasks({Map<String, String>? filters}) async {
    loading = true;
    notifyListeners();
    final res = await ApiService.fetchTasks(filters: filters);
    if (res['ok'] == true && res['data'] is List) {
      tasks = (res['data'] as List).map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList();
      if (_projects.isNotEmpty) {
        final projectMap = {for (var p in _projects) p.id: p};
        for (var t in tasks) {
          if (projectMap.containsKey(t.projectId)) {
            final project = projectMap[t.projectId]!;
            t.projectName = project.name;
            t.projectColors = project.colors;
          }
        }
      }
    } else {
      tasks = [];
    }
    loading = false;
    notifyListeners();
  }

  Future<void> addTask(Task t) async {
    final res = await ApiService.addTask(t);
    if (res['ok'] == true) {
      final created = Task.fromJson(Map<String, dynamic>.from(res['data']));
      final proj = _projects.firstWhere((p) => p.id == created.projectId, orElse: () => Project(id: '', name: '', colors: []));
      if (proj.id.isNotEmpty) {
        created.projectName = proj.name;
        created.projectColors = proj.colors;
      }
      tasks.insert(0, created);
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Add task failed');
    }
  }

  Future<void> updateTask(Task t) async {
    final patch = t.toJson();
    final res = await ApiService.updateTask(t.id, patch);
    if (res['ok'] == true) {
      final updated = Task.fromJson(Map<String, dynamic>.from(res['data']));
      final proj = _projects.firstWhere((p) => p.id == updated.projectId, orElse: () => Project(id: '', name: '', colors: []));
      if (proj.id.isNotEmpty) {
        updated.projectName = proj.name;
        updated.projectColors = proj.colors;
      }
      final idx = tasks.indexWhere((x) => x.id == t.id);
      if (idx != -1) tasks[idx] = updated;
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Update failed');
    }
  }

  Future<void> completeTask(Task t, bool done) async {
    final res = await ApiService.completeTask(t.id, done);
    if (res['ok'] == true) {
      final updatedFromServer = Task.fromJson(Map<String, dynamic>.from(res['data']));
      final idx = tasks.indexWhere((x) => x.id == t.id);
      if (idx != -1) {
        updatedFromServer.projectName = tasks[idx].projectName;
        updatedFromServer.projectColors = tasks[idx].projectColors;
        tasks[idx] = updatedFromServer;
      }
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Complete failed');
    }
  }

  // --- HÀM ĐÃ ĐƯỢC SỬA LẠI ---
  Future<void> deleteTask(String id) async {
    final res = await ApiService.deleteTask(id);
    if (res['ok'] == true) {
      // Xóa task khỏi danh sách cục bộ
      tasks.removeWhere((x) => x.id == id);
      // Thông báo cho UI cập nhật
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Delete failed');
    }
  }
  // -----------------------------



  Future<void> loadStats() async {
    final res = await ApiService.getStats();
    if (res['ok'] == true) {
      stats = res['data'];
      notifyListeners();
    }
  }
}