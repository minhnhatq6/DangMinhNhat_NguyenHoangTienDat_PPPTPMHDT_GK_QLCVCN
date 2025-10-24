// lib/providers/milestone_provider.dart
import 'package:flutter/material.dart';
import '../models/milestone.dart';
import '../services/api_service.dart';

class MilestoneProvider extends ChangeNotifier {
  List<Milestone> milestones = [];
  bool loading = false;

  Future<void> loadMilestones({String? projectId}) async {
    loading = true;
    notifyListeners();
    try {
      final filters = <String, String>{};
      if (projectId != null && projectId.isNotEmpty) filters['project'] = projectId;
      final res = await ApiService.fetchMilestones(filters: filters.isEmpty ? null : filters);
      if (res['ok'] == true && res['data'] is List) {
        final list = (res['data'] as List).map((e) {
          return Milestone.fromJson(Map<String, dynamic>.from(e));
        }).toList();
        milestones = list;
      } else {
        milestones = [];
      }
    } catch (e) {
      milestones = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Milestone?> addMilestone(Milestone m) async {
    final res = await ApiService.addMilestone(m.toJson());
    if (res['ok'] == true) {
      final created = Milestone.fromJson(Map<String, dynamic>.from(res['data']));
      milestones.insert(0, created);
      notifyListeners();
      return created;
    } else {
      throw Exception(res['message'] ?? 'Add milestone failed');
    }
  }

  Future<Milestone?> updateMilestone(String id, Map<String, dynamic> patch) async {
    final res = await ApiService.updateMilestone(id, patch);
    if (res['ok'] == true) {
      final updated = Milestone.fromJson(Map<String, dynamic>.from(res['data']));
      final idx = milestones.indexWhere((m) => m.id == id);
      if (idx != -1) {
        milestones[idx] = updated;
      } else {
        // fallback: put at top
        milestones.insert(0, updated);
      }
      notifyListeners();
      return updated;
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

  Future<void> completeMilestone(String id, bool done) async {
    // backend supports PUT patch with 'completed'
    await updateMilestone(id, {'completed': done});
  }
}
