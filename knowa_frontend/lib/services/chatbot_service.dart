import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/faq_model.dart';

class ChatbotService {
  final _storage = const FlutterSecureStorage();

  // ✅ CORRECT: Pointing to your live Railway server
  final String _baseUrl = 'https://knowa.up.railway.app/api';

  // 1. Send Message
  Future<String> sendMessage(String message) async {
    final url = Uri.parse('$_baseUrl/users/chatbot/');
    final token = await _storage.read(key: 'access_token');

    // Prepare headers
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Only add token if it exists
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      url,
      headers: headers,
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

    // ✅ FIX: Don't send "Bearer null". Send NO header if guest.
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FAQ.fromJson(json)).toList();
    } else {
      // If error, return empty list to prevent app crash
      print("FAQ Fetch Failed: ${response.statusCode}");
      return [];
    }
  }
}