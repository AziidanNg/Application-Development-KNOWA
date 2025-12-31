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

  // --- NEW METHOD: Fixes the error in Group Info Screen ---
  Future<Map<String, dynamic>> getGroupDetails(int roomId) async {
    final token = await _storage.read(key: 'access_token');
    // This assumes your Django URL is configured as /api/chat/rooms/<id>/
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

  // --- NEW METHOD: For the Pinning Feature ---
  Future<void> togglePinMessage(int messageId) async {
    final token = await _storage.read(key: 'access_token');
    // You will need to add this endpoint to your Django urls.py later
    final response = await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/pin/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to pin message');
    }
  }

  Future<int?> getCurrentUserId() async {
    final token = await _storage.read(key: 'access_token');
    // We need to call an endpoint that returns "My Profile"
    // Assuming you have: /api/users/me/ or similar
    // If not, use any endpoint that returns user info.
    
    // TEMPORARY FIX if you don't have a /me endpoint ready:
    // We will fetch the list of chat rooms, and try to find "my" ID from the participant list of the first room.
    // Ideally, you should have an endpoint: GET /api/users/me/
    
    try {
        final response = await http.get(
          Uri.parse('$_baseUrl/../users/me/'), // Adjust based on your actual User API URL
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data['id'];
        }
    } catch (e) {
        print("Error getting user ID: $e");
    }
    return null;
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
}