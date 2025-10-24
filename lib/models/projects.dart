class Project {
  String id;
  String name;
  List<String> colors; // <-- THAY ĐỔI TỪ String? sang List<String>
  String? description;
  String? userId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Project({
    required this.id,
    required this.name,
    this.colors = const [], // <-- THAY ĐỔI: Giá trị mặc định là một list rỗng
    this.description,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? s) {
      if (s == null) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    // <-- THAY ĐỔI: Chuyển đổi từ json array sang List<String>
    List<String> colorsFromJson(dynamic jsonColors) {
      if (jsonColors is List) {
        return jsonColors.map((c) => c.toString()).toList();
      }
      return [];
    }

    return Project(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      colors: colorsFromJson(json['colors']), // <-- THAY ĐỔI
      description: json['description']?.toString(),
      userId: json['userId']?.toString(),
      createdAt: tryParse(json['createdAt']?.toString()),
      updatedAt: tryParse(json['updatedAt']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // <-- THAY ĐỔI: Gửi đi một mảng các màu
      if (colors.isNotEmpty) 'colors': colors,
      if (description != null) 'description': description,
    };
  }
}