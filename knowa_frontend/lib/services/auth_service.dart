import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:knowa_frontend/models/pending_user.dart';

class AuthService {
  // Use 10.0.2.2 for the Android emulator to connect to your PC's localhost
  final String _baseUrl = 'http://10.0.2.2:8000/api/users/';
  final _storage = const FlutterSecureStorage();

  // --- REGISTRATION ---
  Future<Map<String, dynamic>> registerUser(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}register/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': username,
          'email': email,
          'password': password,
          'password2': password, // Our serializer needs this to confirm
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed. Is the server running?'};
    }
  }

  // --- LOGIN ---
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}login/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String accessToken = responseBody['access'];

        // Securely store the token
        await _storage.write(key: 'access_token', value: accessToken);

        // --- NEW LOGIC ---
        // Decode the token to get the user's data
        Map<String, dynamic> userData = JwtDecoder.decode(accessToken);
        return {
          'username': userData['username'],
          'member_status': userData['member_status'],
          'is_staff': userData['is_staff'],
        };
        
      } else {
        // Login failed
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    // Delete the tokens from secure storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // --- ADMIN: GET PENDING USERS ---
Future<List<PendingUser>> getPendingUsers() async {
  final token = await _storage.read(key: 'access_token');
  try {
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/pending/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the admin's token
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => PendingUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending users.');
    }
  } catch (e) {
    throw Exception('Connection failed: ${e.toString()}');
  }
}

// --- ADMIN: UPDATE USER STATUS ---
// This one function will handle approve, reject, and interview
Future<bool> updateUserStatus(int userId, String action) async {
  final token = await _storage.read(key: 'access_token');
  String endpoint = '';

  if (action == 'APPROVE') {
    endpoint = 'admin/approve/$userId/';
  } else if (action == 'REJECT') {
    endpoint = 'admin/reject/$userId/';
  } else if (action == 'INTERVIEW') {
    endpoint = 'admin/interview/$userId/';
  } else {
    return false; // Invalid action
  }

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200; // Return true if successful
  } catch (e) {
    return false;
  }
}
}