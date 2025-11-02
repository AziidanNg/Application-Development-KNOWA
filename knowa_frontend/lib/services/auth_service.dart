import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}login/'), // This calls the TokenObtainPairView
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> tokens = jsonDecode(response.body);
        // Securely store the access and refresh tokens
        await _storage.write(key: 'access_token', value: tokens['access']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}