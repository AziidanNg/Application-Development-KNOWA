// lib/services/donation_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:knowa_frontend/models/donation.dart';

class DonationService {
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api/donations/'
      : 'http://127.0.0.1:8000/api/donations/';

  final _storage = const FlutterSecureStorage();

  // 1. Fetches the donation goal and current total
  Future<Map<String, dynamic>> getDonationGoal() async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}goal/'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load donation goal.');
      }
    } catch (e) {
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  // 2. Submits the new donation (amount + receipt)
  Future<Map<String, dynamic>> submitDonation({
    required String amount,
    required File receiptFile,
  }) async {

    final token = await _storage.read(key: 'access_token');
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${_baseUrl}create/'), // Calls your DonationCreateView
    );

    // Add the fields
    request.fields['amount'] = amount;
    request.headers['Authorization'] = 'Bearer $token';

    // Add the receipt file
    final mimeType = lookupMimeType(receiptFile.path);
    final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

    request.files.add(
      await http.MultipartFile.fromPath(
        'receipt', // Must match your Django 'receipt' model field
        receiptFile.path,
        contentType: mediaType,
      ),
    );

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) { // 201 Created
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': responseData};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  // --- ADMIN: GET PENDING DONATIONS ---
  Future<List<Donation>> getPendingDonations() async {
    final token = await _storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}admin/pending/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Donation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending donations.');
      }
    } catch (e) {
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  // --- ADMIN: APPROVE A DONATION ---
  Future<bool> approveDonation(int id) async {
    final token = await _storage.read(key: 'access_token');
    try {
      // --- CHANGE THIS URL ---
      // OLD: Uri.parse('$_baseUrl$id/approve/')
      // NEW: Matches 'admin/approve/<int:pk>/' from your urls.py
      final response = await http.post(
        Uri.parse('${_baseUrl}admin/approve/$id/'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // FIX 2: Reject Function
  Future<bool> rejectDonation(int id, {String? reason}) async {
    final token = await _storage.read(key: 'access_token');
    try {
      // --- CHANGE THIS URL ---
      // OLD: Uri.parse('$_baseUrl$id/reject/')
      // NEW: Matches 'admin/reject/<int:pk>/' from your urls.py
      final response = await http.post(
        Uri.parse('${_baseUrl}admin/reject/$id/'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reason': reason ?? 'Issue with donation'
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error rejecting donation: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLatestIssue() async {
    final token = await _storage.read(key: 'access_token');
    try {
      // --- THE FIX ---
      // We remove 'donations/' because _baseUrl likely already includes it.
      // Correct URL: .../api/donations/my-latest-issue/
      final response = await http.get(
        Uri.parse('${_baseUrl}my-latest-issue/'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Check Issue Status: ${response.statusCode}"); // Debug print
      print("Check Issue Body: ${response.body}");       // Debug print

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error fetching latest issue: $e");
      return null;
    }
  }

  // Function to re-upload receipt and fix donation
  Future<bool> fixDonation(int id, File receiptFile) async {
    final token = await _storage.read(key: 'access_token');
    
    // Create Multipart request for file upload
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse('${_baseUrl}$id/fix/'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    
    // Attach the new file
    request.files.add(
      await http.MultipartFile.fromPath('receipt', receiptFile.path),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
      print("Error fixing donation: $e");
      return false;
    }
  }
}