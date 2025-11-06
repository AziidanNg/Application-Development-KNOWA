import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for the Android emulator to connect to your PC's localhost
  final String _baseUrl = 'http://10.0.2.2:8000/api/users/';
  final _storage = const FlutterSecureStorage();

  // --- REGISTRATION ---
  Future<Map<String, dynamic>> registerUser({
  required String name,
  required String email,
  required String phone,
  required String password,
  required List<String> interests,
  }) async {
  try {
    // --- NEW: Join the interests list into a single string ---
    String interestsString = interests.join(','); // e.g., "Education,Arts"

    final response = await http.post(
      Uri.parse('${_baseUrl}register/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        // We'll use the email as the username for simplicity
        'username': email, 
        'email': email,
        'first_name': name, // This is for the "Name" field
        'phone': phone,
        'interests': interestsString,
        'password': password,
        'password2': password,
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
  // --- REPLACE your loginUser function with this ---
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}login/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String accessToken = responseBody['access'];

        // 1. Securely store the token
        await _storage.write(key: 'access_token', value: accessToken);

        // 2. Decode the token to get the user's data
        Map<String, dynamic> userData = JwtDecoder.decode(accessToken);

        // 3. --- NEW: Save user data to SharedPreferences ---
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', userData['username']);
        await prefs.setString('member_status', userData['member_status']);
        await prefs.setBool('is_staff', userData['is_staff']);
        await prefs.setString('first_name', userData['first_name']);
        // ----------------------------------------------
        
        return userData; // Return the data for the login screen
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // --- ADD THIS NEW FUNCTION ---
  Future<Map<String, dynamic>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? 'User',
      'member_status': prefs.getString('member_status') ?? 'PUBLIC',
      'is_staff': prefs.getBool('is_staff') ?? false,
      'first_name': prefs.getString('first_name') ?? prefs.getString('username') ?? 'User',
    };
  }

  Future<void> logout() async {
    // Delete the tokens from secure storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');

    // --- NEW: Clear the user data ---
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('member_status');
    await prefs.remove('is_staff');
    await prefs.remove('first_name');
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