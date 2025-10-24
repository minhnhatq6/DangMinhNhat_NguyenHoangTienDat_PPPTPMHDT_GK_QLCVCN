class Task {
  String id;
  String title;
  String? note;
  DateTime? dueDate;
  bool isDone;
  DateTime? completedAt;
  int priority;
  String? projectId;
  String? projectName;
  List<String> projectColors;
  String category;
  int progress;

  Task({
    required this.id,
    required this.title,
    this.note,
    this.dueDate,
    this.isDone = false,
    this.completedAt,
    this.priority = 1,
    this.projectId,
    this.projectName,
    this.projectColors = const [],
    this.category = '',
    this.progress = 0,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }

    List<String> _colorsFromJson(dynamic jsonField) {
      if (jsonField is List) {
        return jsonField.map((c) => c.toString()).toList();
      }
      return [];
    }

    String? projectId;
    String? projectName;
    List<String> projectColors = [];

    if (json['project'] != null) {
      if (json['project'] is Map) {
        final p = Map<String, dynamic>.from(json['project']);
        projectId = (p['_id'] ?? p['id'])?.toString();
        projectName = p['name']?.toString();
        projectColors = _colorsFromJson(p['colors']);
      } else {
        projectId = json['project']?.toString();
      }
    }

    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      note: json['note'],
      dueDate: parseDate(json['dueDate']),
      isDone: json['isDone'] == true,
      completedAt: parseDate(json['completedAt']),
      priority: (json['priority'] is int) ? json['priority'] : (int.tryParse(json['priority']?.toString() ?? '') ?? 1),
      projectId: projectId,
      projectName: projectName,
      projectColors: projectColors,
      category: json['category'] ?? '',
      progress: (json['progress'] is int) ? json['progress'] : (int.tryParse(json['progress']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
      'project': projectId,
      'category': category,
      'progress': progress,
    };
  }

  String get dueDateText {
    final d = dueDate;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}