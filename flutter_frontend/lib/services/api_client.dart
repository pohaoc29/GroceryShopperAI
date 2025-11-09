import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const bool useAndroidEmulator = false;
final String apiBase = useAndroidEmulator
    ? 'http://10.0.2.2:8000/api'
    : 'http://localhost:8000/api';
final String wsUrl =
    useAndroidEmulator ? 'ws://10.0.2.2:8000/ws' : 'ws://localhost:8000/ws';

final storage = FlutterSecureStorage();

class ApiClient {
  String? token;

  Future<Map<String, String>> _headers() async {
    final h = {'Content-Type': 'application/json'};
    final t = token ?? await storage.read(key: 'token');
    print(
        '[ApiClient] Token: ${t != null ? "found (${t.substring(0, 20)}...)" : "null"}');
    if (t != null) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<Map<String, dynamic>> post(String path, Map body) async {
    print('[ApiClient] POST $path with body: $body');
    final res = await http.post(Uri.parse(apiBase + path),
        headers: await _headers(), body: jsonEncode(body));
    print('[ApiClient] POST response: ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && (j['detail'] != null || j['error'] != null)) {
          msg = (j['detail'] ?? j['error']).toString();
        } else {
          msg = jsonEncode(j);
        }
      } catch (_) {}
      throw Exception('HTTP ${res.statusCode}: $msg');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res =
        await http.get(Uri.parse(apiBase + path), headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRooms() async {
    final res = await get('/rooms');
    return res['rooms'] as List<dynamic>;
  }

  Future<List<dynamic>> getRoomMessages(int roomId) async {
    final res = await get('/rooms/$roomId/messages');
    return res['messages'] as List<dynamic>;
  }

  Future<List<dynamic>> getRoomMembers(int roomId) async {
    final res = await get('/rooms/$roomId/members');
    return res['members'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> postRoomMessage(
      int roomId, String content) async {
    return await post('/rooms/$roomId/messages', {'content': content});
  }

  Future<Map<String, dynamic>> createRoom(String name) async {
    return await post('/rooms', {'name': name});
  }

  Future<Map<String, dynamic>> inviteToRoom(int roomId, String username) async {
    return await post('/rooms/$roomId/invite', {'username': username});
  }
}

final apiClient = ApiClient();
