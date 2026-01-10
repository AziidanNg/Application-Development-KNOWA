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
import 'package:knowa_frontend/models/notification_item.dart';

class AuthService {
  // Use 10.0.2.2 for the Android emulator to connect to your PC's localhost
  final String _baseUrl = 'http://knowa.up.railway.app/api/users/';
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
        await prefs.setString('access', accessToken); // We save it as 'access' to match InterviewService
        await prefs.setString('username', userData['username']);
        await prefs.setString('member_status', userData['member_status']);
        await prefs.setBool('is_staff', userData['is_staff']);
        await prefs.setString('first_name', userData['first_name']);
        await prefs.setString('phone', userData['phone']);
        await prefs.setBool('has_receipt', userData['has_receipt'] ?? false);
        await prefs.setString('rejection_reason', userData['rejection_reason'] ?? '');

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
  // Change return type to nullable Map
  Future<Map<String, dynamic>?> getUserData() async {
    
    // 1. CRITICAL: Check if the token actually exists in secure storage
    final token = await _storage.read(key: 'access_token');
    
    // If no token is found, return null immediately. 
    // This tells SplashScreen to go to Login, not Dashboard.
    if (token == null) return null; 

    // 2. If token exists, fetch the saved user details
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Double-check: If we logged out, we cleared 'username', so this might be missing too.
    if (!prefs.containsKey('username')) return null;

    return {
      'username': prefs.getString('username') ?? 'User',
      'member_status': prefs.getString('member_status') ?? 'PUBLIC',
      'is_staff': prefs.getBool('is_staff') ?? false,
      'first_name': prefs.getString('first_name') ?? prefs.getString('username') ?? 'User',
      'phone': prefs.getString('phone') ?? 'N/A',
      'has_receipt': prefs.getBool('has_receipt') ?? false,
      'rejection_reason': prefs.getString('rejection_reason'),
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
Future<bool> updateUserStatus(
    int userId, 
    String status, 
    {
      String? reason, // <--- Renamed from 'rejectionReason' to match your screens
      String? date,   // <--- Renamed from 'interviewDate' to match your screens
      String? link,   // <--- Renamed from 'meetingLink' to match your screens
      int? interviewerId, 
    }
  ) async {
    final token = await _storage.read(key: 'access_token');
    
    // Determine the correct endpoint
    String urlStr;
    if (status == 'INTERVIEW') {
      urlStr = '${_baseUrl}admin/interview/$userId/';
    } else if (status == 'REJECT') {
      urlStr = '${_baseUrl}admin/reject/$userId/';
    } else if (status == 'APPROVE_MEMBER') {
      urlStr = '${_baseUrl}admin/approve-member/$userId/';
    } else if (status == 'APPROVE_VOLUNTEER') {
      urlStr = '${_baseUrl}admin/approve-volunteer/$userId/';
    } else {
      return false; 
    }

    try {
      final response = await http.post(
        Uri.parse(urlStr),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status, 
          'reason': reason, // Send 'reason' to backend
          'date_time': date, // Map 'date' -> 'date_time' for backend
          'meeting_link': link, // Map 'link' -> 'meeting_link' for backend
          'interviewer_id': interviewerId, 
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to update status: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating status: $e");
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

// Fetch user's schedule (Interviews + Events)
  Future<List<Map<String, dynamic>>> getMySchedule() async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}my-schedule/'), // Matches users/urls.py
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Cast to List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching schedule: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffList() async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}admin/staff-list/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET Notifications
  Future<List<NotificationItem>> getNotifications() async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}notifications/'), // endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // MARK READ
  Future<void> markNotificationRead(int id) async {
    final token = await _storage.read(key: 'access_token');
    try {
      await http.post(
        Uri.parse('${_baseUrl}notifications/$id/read/'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>?> getFreshProfile() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    // --- FIX: Remove the slash before 'me/' ---
    // _baseUrl already ends with '/', so we just append 'me/'
    final url = Uri.parse('${_baseUrl}me/'); 
    // --------------------------------------------------

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching fresh profile: $e");
    }
    return null;
  }

  // --- FEEDBACK ---
  Future<bool> submitFeedback(String category, String message) async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}feedback/'), // Ensure this matches your urls.py
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category': category,
          'message': message,
        }),
      );
      return response.statusCode == 201; // 201 Created
    } catch (e) {
      return false;
    }
  }

  // --- ADMIN: GET ALL FEEDBACK ---
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}admin/feedback-list/'), // Check your urls.py path!
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print("Error fetching feedback: $e");
      return [];
    }
  }
}