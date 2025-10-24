// lib/models/milestone.dart

class Milestone {
  String id;
  String name;
  String? description;
  String? projectId;
  String? projectName;
  List<String> projectColors;

  // --- THAY ĐỔI ---
  DateTime? date; // Chỉ còn một ngày duy nhất

  DateTime? createdAt;
  DateTime? updatedAt;

  Milestone({
    required this.id,
    required this.name,
    this.description,
    this.projectId,
    this.projectName,
    this.projectColors = const [],

    // --- THAY ĐỔI ---
    this.date,

    this.createdAt,
    this.updatedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    DateTime? _tryParseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }

    List<String> _colorsFromJson(dynamic jsonField) {
      if (jsonField is List) { return jsonField.map((c) => c.toString()).toList(); }
      return [];
    }

    String? projId;
    String? projName;
    List<String> projColors = [];

    if (json['project'] != null) {
      if (json['project'] is Map) {
        final p = Map<String, dynamic>.from(json['project']);
        projId = (p['_id'] ?? p['id'])?.toString();
        projName = p['name']?.toString();
        projColors = _colorsFromJson(p['colors']);
      } else {
        projId = json['project']?.toString();
      }
    } else if (json['projectId'] != null) {
      projId = json['projectId']?.toString();
    }

    return Milestone(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      projectId: projId,
      projectName: projName,
      projectColors: projColors,

      // --- THAY ĐỔI ---
      date: _tryParseDate(json['date']),

      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (projectId != null) 'project': projectId,
      'name': name,
      if (description != null) 'description': description,

      // --- THAY ĐỔI ---
      if (date != null) 'date': date!.toIso8601String(),
    };
  }

  @override
  String toString() => 'Milestone($id, $name)';
}