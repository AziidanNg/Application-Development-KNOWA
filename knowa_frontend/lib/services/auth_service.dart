import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:knowa_frontend/models/pending_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:knowa_frontend/models/admin_stats.dart';

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
  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}login/'), // This now calls LoginRequestTACView
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      // 200 OK means the password was correct and the email was sent
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- NEW 2FA VERIFICATION FUNCTION ---
  // This function verifies the TAC and *actually* logs the user in.
  Future<Map<String, dynamic>?> verifyTAC(String username, String tacCode) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}verify-2fa/'), // This calls LoginVerifyTACView
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'username': username,
          'tac_code': tacCode,
        }),
      );

      if (response.statusCode == 200) {
        // SUCCESS! The TAC was correct.
        // The server has sent us the login tokens.
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String accessToken = responseBody['access'];

        // 1. Securely store the token
        await _storage.write(key: 'access_token', value: accessToken);

        // 2. Decode the token to get the user's data
        Map<String, dynamic> userData = JwtDecoder.decode(accessToken);

        // 3. Save user data to SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', userData['username']);
        await prefs.setString('member_status', userData['member_status']);
        await prefs.setBool('is_staff', userData['is_staff']);
        await prefs.setString('first_name', userData['first_name']);
        await prefs.setString('phone', userData['phone']);
        await prefs.setBool('has_receipt', userData['has_receipt'] ?? false);

        return userData; // Return the user data to navigate to the correct dashboard
      } else {
        // TAC was wrong, expired, or user not found
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
      'phone': prefs.getString('phone') ?? 'N/A',
      'has_receipt': prefs.getBool('has_receipt') ?? false,
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
    await prefs.remove('phone');
  }

// REQUESTING a password reset
Future<Map<String, dynamic>> requestPasswordReset(String email) async {
  try {
    final response = await http.post(
      Uri.parse('${_baseUrl}password-reset/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );
    return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
  } catch (e) {
    return {'success': false, 'error': 'Connection failed.'};
  }
}

// For CONFIRMING the new password
Future<Map<String, dynamic>> confirmPasswordReset({
  required String email,
  required String tacCode,
  required String password,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${_baseUrl}password-reset/confirm/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(<String, String>{
        'email': email,
        'tac_code': tacCode,
        'password': password,
      }),
    );
    return {'success': response.statusCode == 200, 'data': jsonDecode(response.body)};
  } catch (e) {
    return {'success': false, 'error': 'Connection failed.'};
  }
}

// --- NEW FUNCTION for Submitting Application ---
Future<Map<String, dynamic>> applyForMembership({
  required String applicationType,
  required String education,
  required String occupation,
  required String reason,
  required String icNumber,
  File? resumeFile, // For resume.pdf
  File? idFile,     // For ID.jpg
}) async {

  final token = await _storage.read(key: 'access_token');
  var request = http.MultipartRequest(
    'PUT', // We use PUT/PATCH to update an existing profile
    Uri.parse('${_baseUrl}apply/'), // Calls your SubmitApplicationView
  );

  // Add all the text fields
  request.fields['application_type'] = applicationType; 
  request.fields['education'] = education;
  request.fields['occupation'] = occupation;
  request.fields['reason_for_joining'] = reason;
  request.fields['ic_number'] = icNumber;

  // --- Add the resume file (if it exists) ---
  if (resumeFile != null) {
    // Get MIME type (e.g., 'application/pdf')
    final mimeType = lookupMimeType(resumeFile.path);
    final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

    request.files.add(
      await http.MultipartFile.fromPath(
        'resume', // Must match your Django 'resume' model field
        resumeFile.path,
        contentType: mediaType,
      ),
    );
  }

  // --- Add the ID file (if it exists) ---
  if (idFile != null) {
    final mimeType = lookupMimeType(idFile.path);
    final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

    request.files.add(
      await http.MultipartFile.fromPath(
        'identification', // Must match your Django 'identification' model field
        idFile.path,
        contentType: mediaType,
      ),
    );
  }

  // Add the authorization token
  request.headers['Authorization'] = 'Bearer $token';

  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) { // 200 OK for an update
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('member_status', 'PENDING');
      return {'success': true, 'data': responseData};
    } else {
      return {'success': false, 'error': responseData};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
  }
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
// It now accepts 'APPROVE_MEMBER' and 'APPROVE_VOLUNTEER'
Future<bool> updateUserStatus(int userId, String action) async {
  final token = await _storage.read(key: 'access_token');
  String endpoint = '';

  // --- NEW LOGIC ---
  if (action == 'APPROVE_MEMBER') {
    endpoint = 'admin/approve-member/$userId/';
  } else if (action == 'APPROVE_VOLUNTEER') {
    endpoint = 'admin/approve-volunteer/$userId/';
  } else if (action == 'REJECT') {
    endpoint = 'admin/reject/$userId/';
  } else if (action == 'INTERVIEW') {
    endpoint = 'admin/interview/$userId/';
  } else {
    return false; // Invalid action
  }
  // --- END NEW LOGIC ---

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

// This allows the user to upload their payment receipt
Future<bool> uploadReceipt(File receiptFile) async {
  final token = await _storage.read(key: 'access_token');
  var request = http.MultipartRequest(
    'PUT', // We use PUT/PATCH to update an existing profile
    Uri.parse('${_baseUrl}upload-receipt/'), // Calls your UploadReceiptView
  );

  // --- Add the receipt file ---
  final mimeType = lookupMimeType(receiptFile.path);
  final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

  request.files.add(
    await http.MultipartFile.fromPath(
      'payment_receipt', // Must match your Django 'payment_receipt' model field
      receiptFile.path,
      contentType: mediaType,
    ),
  );

  // Add the authorization token
  request.headers['Authorization'] = 'Bearer $token';

  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_receipt', true);
    return response.statusCode == 200; // 200 OK for an update
  } catch (e) {
    return false;
  }
}

// --- ADMIN: GET USERS AWAITING PAYMENT ---
Future<List<PendingUser>> getPendingPayments() async {
  final token = await _storage.read(key: 'access_token');
  try {
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/pending-payments/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      // We can reuse the PendingUser model, it has all the data we need
      return jsonList.map((json) => PendingUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending payments.');
    }
  } catch (e) {
    throw Exception('Connection failed: ${e.toString()}');
  }
}

// --- ADMIN: CONFIRM A USER'S PAYMENT ---
Future<bool> confirmPayment(int userId) async {
  final token = await _storage.read(key: 'access_token');
  try {
    final response = await http.post(
      Uri.parse('${_baseUrl}admin/confirm-payment/$userId/'),
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

// --- ADMIN: REJECT A PAYMENT ---
Future<bool> rejectPayment(int userId) async {
  final token = await _storage.read(key: 'access_token');
  try {
    final response = await http.post(
      Uri.parse('${_baseUrl}admin/reject-payment/$userId/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

Future<AdminStats> getAdminStats() async {
  final token = await _storage.read(key: 'access_token');
  try {
    final response = await http.get(
      Uri.parse('${_baseUrl}admin/stats/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return AdminStats.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load admin stats.');
    }
  } catch (e) {
    throw Exception('Connection failed: ${e.toString()}');
  }
}
}