import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
// --- FIX 1: ADD THIS IMPORT ---
import 'package:shared_preferences/shared_preferences.dart'; 

class ChatService {
  // NOTE: Change to your IP (10.0.2.2 for Emulator) or deployed URL
  final String _baseUrl = 'https://knowa.up.railway.app/api/chat'; 
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

  Future<Map<String, dynamic>> getGroupDetails(int roomId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/rooms/$roomId/'), 
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load group details: ${response.statusCode}');
    }
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

  Future<void> togglePinMessage(int messageId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/pin/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to pin message');
    }
  }

  Future<void> markMessagesAsRead(int roomId) async {
    final token = await _storage.read(key: 'access_token');
    try {
      await http.post(
        Uri.parse('$_baseUrl/rooms/$roomId/read/'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  Future<Map<String, dynamic>> getMessageInfo(int messageId) async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/$messageId/info/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load info');
    }
  }

  // 1. Get List of Users to Chat With
  Future<List<dynamic>> getUserOptions() async {
    final url = Uri.parse('https://knowa.up.railway.app/api/users/admin/user-options/'); 
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Create the Chat Room
  Future<bool> createChatRoom(String name, List<int> participantIds, String type) async {
    // --- FIX 2: Use _baseUrl (with underscore) ---
    final url = Uri.parse('$_baseUrl/create/'); 
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access');

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'participants': participantIds,
          'type': type
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChatRoom(int roomId) async {
    final token = await _storage.read(key: 'access_token');
    
    // Change URL to match your backend
    final url = Uri.parse('$_baseUrl/rooms/$roomId/delete/');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // 204 No Content means successful deletion
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting chat: $e");
      return false;
    }
  }
}