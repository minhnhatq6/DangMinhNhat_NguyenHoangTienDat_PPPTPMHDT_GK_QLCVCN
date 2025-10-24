import 'package:flutter/material.dart';
import '../models/projects.dart';
import '../services/api_service.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> projects = [];
  bool loading = false;

  Future<void> loadProjects() async {
    loading = true;
    notifyListeners();
    final res = await ApiService.fetchProjects();
    if (res['ok'] == true && res['data'] is List) {
      projects = (res['data'] as List).map((e) => Project.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      projects = [];
    }
    loading = false;
    notifyListeners();
  }

  // --- HÀM ĐÃ ĐƯỢC THAY ĐỔI ---
  // Giờ đây nó trả về một đối tượng Project sau khi tạo thành công
  Future<Project> addProject(String name, {String? desc, List<String>? colors}) async {
    final res = await ApiService.addProject(name, description: desc, colors: colors);
    if (res['ok'] == true) {
      // 1. Parse project mới từ response của API
      final created = Project.fromJson(Map<String, dynamic>.from(res['data']));
      // 2. Thêm nó vào danh sách cục bộ
      projects.insert(0, created);
      notifyListeners();
      // 3. Trả về chính project vừa tạo
      return created;
    } else {
      throw Exception(res['message'] ?? 'Add project failed');
    }
  }
  // -------------------------

  Future<void> updateProject(String id, {required String name, String? desc, List<String>? colors}) async {
    final data = {
      'name': name,
      if (desc != null) 'description': desc,
      if (colors != null) 'colors': colors,
    };
    final res = await ApiService.updateProject(id, data);
    if (res['ok'] == true) {
      final updated = Project.fromJson(Map<String, dynamic>.from(res['data']));
      final index = projects.indexWhere((p) => p.id == id);
      if (index != -1) {
        projects[index] = updated;
        notifyListeners();
      }
    } else {
      throw Exception(res['message'] ?? 'Update project failed');
    }
  }

  Future<void> deleteProject(String id) async {
    final res = await ApiService.deleteProject(id);
    if (res['ok'] == true) {
      projects.removeWhere((p) => p.id == id);
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Delete project failed');
    }
  }
}