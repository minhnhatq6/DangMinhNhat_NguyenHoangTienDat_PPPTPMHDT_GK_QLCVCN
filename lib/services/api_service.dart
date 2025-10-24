import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class ApiService {
  static String get _base {
    if (kIsWeb) return 'http://localhost:5000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
      if (Platform.isIOS) return 'http://localhost:5000/api';
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  static const _tokenKey = 'jwt_token';
  static Future<SharedPreferences> get _sp async => SharedPreferences.getInstance();

  static Future<void> _saveToken(String token) async {
    final sp = await _sp;
    await sp.setString(_tokenKey, token);
  }

  static Future<void> _removeToken() async {
    final sp = await _sp;
    await sp.remove(_tokenKey);
  }

  static Future<String?> _getToken() async {
    final sp = await _sp;
    return sp.getString(_tokenKey);
  }

  static dynamic _safeDecode(String s) {
    try {
      return json.decode(s);
    } catch (_) {
      return s;
    }
  }

  // ---------- AUTH ----------
  static Future<Map<String, dynamic>> register(String email, String password, {String? displayName}) async {
    try {
      final res = await http.post(Uri.parse('$_base/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'password': password, 'displayName': displayName})).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body is Map && body['token'] != null) await _saveToken(body['token']);
        return {'ok': true, 'data': body};
      }
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(Uri.parse('$_base/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'password': password})).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) {
        if (body is Map && body['token'] != null) await _saveToken(body['token']);
        return {'ok': true, 'data': body};
      }
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> me() async {
    try {
      final token = await _getToken();
      if (token == null) return {'ok': false, 'message': 'No token'};
      final res = await http.get(Uri.parse('$_base/auth/me'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<void> logout() async {
    await _removeToken();
  }

  // ---------- TASKS ----------
  static Future<Map<String, dynamic>> fetchTasks({Map<String, String>? filters}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_base/tasks').replace(queryParameters: filters);
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addTask(Task t) async {
    try {
      final token = await _getToken();
      final res = await http.post(Uri.parse('$_base/tasks'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode(t.toJson())).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> patch) async {
    try {
      final token = await _getToken();
      final res = await http.put(Uri.parse('$_base/tasks/$id'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode(patch)).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> completeTask(String id, bool done) async {
    try {
      final token = await _getToken();
      final res = await http.post(Uri.parse('$_base/tasks/$id/complete'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode({'done': done})).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> archiveTask(String id, bool archived) async {
    try {
      final token = await _getToken();
      final res = await http.post(Uri.parse('$_base/tasks/$id/archive'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode({'archived': archived})).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteTask(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(Uri.parse('$_base/tasks/$id'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchCalendar(DateTime start, DateTime end) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_base/tasks/calendar').replace(queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String()
      });
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _getToken();
      final res = await http.get(Uri.parse('$_base/tasks/stats'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ---------- PROJECTS ----------
  static Future<Map<String, dynamic>> fetchProjects() async {
    try {
      final token = await _getToken();
      final res = await http.get(Uri.parse('$_base/projects'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  // ------------------- HÀM ĐÃ ĐƯỢC SỬA -------------------
  static Future<Map<String, dynamic>> addProject(String name, {List<String>? colors, String? description}) async {
    try {
      final token = await _getToken();

      // Tạo body cho request, chỉ thêm các trường có giá trị
      final Map<String, dynamic> bodyData = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (colors != null && colors.isNotEmpty) 'colors': colors,
      };

      final res = await http.post(Uri.parse('$_base/projects'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode(bodyData)).timeout(const Duration(seconds: 10)); // Gửi bodyData đã được encode

      final body = _safeDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }
  static Future<Map<String, dynamic>> updateProject(String id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$_base/projects/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteProject(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('$_base/projects/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));

      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }
  // -----------------------------------------------------------

  // ---------- MILESTONES ----------
  static Future<Map<String, dynamic>> fetchMilestones({Map<String, String>? filters}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_base/milestones').replace(queryParameters: filters);
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addMilestone(dynamic m) async {
    try {
      final token = await _getToken();
      dynamic bodyData;
      if (m is Map<String, dynamic>) {
        bodyData = m;
      } else {
        try {
          bodyData = (m as dynamic).toJson();
        } catch (_) {
          bodyData = m;
        }
      }
      final res = await http.post(Uri.parse('$_base/milestones'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode(bodyData)).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateMilestone(String id, Map<String, dynamic> patch) async {
    try {
      final token = await _getToken();
      final res = await http.put(Uri.parse('$_base/milestones/$id'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode(patch)).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteMilestone(String id) async {
    try {
      final token = await _getToken();
      final res = await http.delete(Uri.parse('$_base/milestones/$id'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  /// If backend supports a dedicated complete endpoint (/milestones/:id/complete)
  static Future<Map<String, dynamic>> completeMilestone(String id, bool done) async {
    try {
      final token = await _getToken();
      final res = await http.post(Uri.parse('$_base/milestones/$id/complete'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: json.encode({'done': done})).timeout(const Duration(seconds: 10));
      final body = _safeDecode(res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body};
      return {'ok': false, 'message': body is Map ? (body['message'] ?? body.toString()) : body.toString()};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

}

