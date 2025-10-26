import 'package:flutter/material.dart';
import '../models/milestone.dart';
import '../services/api_service.dart';

class MilestoneProvider extends ChangeNotifier {
  List<Milestone> milestones = [];
  bool loading = false;

  Future<void> loadMilestones({String? projectId}) async {
    loading = true;
    notifyListeners();

    final filters = projectId != null ? {'project': projectId} : null;
    final res = await ApiService.fetchMilestones(filters: filters);

    if (res['ok'] == true && res['data'] is List) {
      milestones = (res['data'] as List)
          .map((e) => Milestone.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      milestones = [];
    }

    loading = false;
    notifyListeners();
  }

  Future<void> addMilestone(Milestone m) async {
    final res = await ApiService.addMilestone(m.toJson());
    if (res['ok'] == true) {
      final created = Milestone.fromJson(Map<String, dynamic>.from(res['data']));
      milestones.insert(0, created);
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Add milestone failed');
    }
  }

  Future<void> updateMilestone(String id, Map<String, dynamic> data) async {
    final res = await ApiService.updateMilestone(id, data);
    if (res['ok'] == true) {
      final updated = Milestone.fromJson(Map<String, dynamic>.from(res['data']));
      final index = milestones.indexWhere((m) => m.id == id);
      if (index != -1) {
        milestones[index] = updated;
        notifyListeners();
      }
    } else {
      throw Exception(res['message'] ?? 'Update milestone failed');
    }
  }

  Future<void> deleteMilestone(String id) async {
    final res = await ApiService.deleteMilestone(id);
    if (res['ok'] == true) {
      milestones.removeWhere((m) => m.id == id);
      notifyListeners();
    } else {
      throw Exception(res['message'] ?? 'Delete milestone failed');
    }
  }

  // Hàm này có thể bạn chưa có, nhưng rất cần thiết
  Future<void> completeMilestone(String id, bool done) async {
    // API backend của bạn chưa có endpoint này, nhưng đây là cách làm
    final res = await ApiService.updateMilestone(id, {'completed': done});
    if (res['ok'] == true) {
      final updated = Milestone.fromJson(Map<String, dynamic>.from(res['data']));
      final index = milestones.indexWhere((m) => m.id == id);
      if (index != -1) {
        milestones[index] = updated;
        notifyListeners();
      }
    } else {
      throw Exception(res['message'] ?? 'Update milestone failed');
    }
  }
}