// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String boxName = 'tasks_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static List<Map> loadAll() {
    final box = Hive.box(boxName);
    return box.values.cast<Map>().toList();
  }

  static Future<void> save(String id, Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.put(id, data);
  }

  static Future<void> delete(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = Hive.box(boxName);
    await box.clear();
  }
}
