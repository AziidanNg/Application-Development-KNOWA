// lib/services/chat_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ChatService {
  // NOTE: Change to your IP (10.0.2.2 for Emulator) or deployed URL
  final String _baseUrl = 'http://10.0.2.2:8000/api/chat'; 
  final _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getChatRooms() async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/rooms/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load chats');
  }

  Future<List<dynamic>> getMessages(int roomId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/rooms/$roomId/messages/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load messages');
  }

  Future<void> sendMessage(int roomId, String content) async {
    final token = await _storage.read(key: 'access_token');
    await http.post(
      Uri.parse('$_baseUrl/rooms/$roomId/messages/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );
  }
}