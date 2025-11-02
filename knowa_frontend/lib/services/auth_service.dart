import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
}