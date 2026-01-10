import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import '../models/faq_model.dart';

class ChatbotService {
  final _storage = const FlutterSecureStorage();

  // --- UPDATED: PRODUCTION URL ---
  // No need for '10.0.2.2' anymore because this link works from anywhere.
  final String _baseUrl = 'https://knowa.up.railway.app/api';

  // 1. Send Message
  Future<String> sendMessage(String message) async {
    final url = Uri.parse('$_baseUrl/users/chatbot/'); 
    // Add auth headers if your chat requires it, otherwise keep generic
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'];
    } else {
      throw Exception('Failed to connect to AI');
    }
  }

  // 2. Get FAQs
  Future<List<FAQ>> getFAQs() async {
    final url = Uri.parse('$_baseUrl/chatbot/faqs/'); 
    final token = await _storage.read(key: 'access_token'); 

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FAQ.fromJson(json)).toList();
    } else {
      // If error (e.g., 401 Unauthorized), return empty list or throw
      return []; 
    }
  }
}