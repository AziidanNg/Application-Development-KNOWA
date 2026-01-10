// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowa_frontend/models/event.dart'; 
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; 
import 'package:image_picker/image_picker.dart';

class EventService {
  // --- UPDATED: PRODUCTION URL ---
  final String _baseUrl = 'https://knowa.up.railway.app/api/events/';

  // Fetches the list of all events
  Future<List<Event>> getEvents() async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  // Fetches the details for a single event
  Future<Event> getEventDetails(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$eventId/'));

      if (response.statusCode == 200) {
        return Event.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load event details.');
      }
    } catch (e) {
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  // Create an Event
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String location,
    required String startTime,
    required String endTime,
    required int capacityParticipants,
    required int capacityCrew,
    required String status,
    required bool isOnline,
    String? calendarLink,
    XFile? imageFile,
  }) async {

    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      request.fields['title'] = title;
      request.fields['description'] = description;
      if (isOnline && location.trim().isEmpty) {
         request.fields['location'] = 'Online';
      } else {
         request.fields['location'] = location;
      }
      request.fields['start_time'] = startTime;
      request.fields['end_time'] = endTime;
      request.fields['capacity_participants'] = capacityParticipants.toString();
      request.fields['capacity_crew'] = capacityCrew.toString();
      request.fields['status'] = status;
      request.fields['is_online'] = isOnline.toString();
      if (calendarLink != null && calendarLink.isNotEmpty) {
        request.fields['calendar_link'] = calendarLink;
      }

      request.headers['Authorization'] = 'Bearer $token';

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'event_image',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(utf8.decode(response.bodyBytes))};
      } else {
        return {'success': false, 'error': jsonDecode(utf8.decode(response.bodyBytes))};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  // Update an Event
  Future<Map<String, dynamic>> updateEvent(
    int eventId,
    {
    required String title,
    required String description,
    required String location,
    required String startTime,
    required String endTime,
    required int capacityParticipants,
    required int capacityCrew,
    required String status,
    required bool isOnline,
    String? calendarLink,
    XFile? imageFile,
  }) async {

    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');

    try {
      var request = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl$eventId/'));

      request.fields['title'] = title;
      request.fields['description'] = description;
      if (isOnline && location.trim().isEmpty) {
         request.fields['location'] = 'Online';
      } else {
         request.fields['location'] = location;
      }
      request.fields['start_time'] = startTime;
      request.fields['end_time'] = endTime;
      request.fields['capacity_participants'] = capacityParticipants.toString();
      request.fields['capacity_crew'] = capacityCrew.toString();
      request.fields['status'] = status;
      request.fields['is_online'] = isOnline.toString();
      if (calendarLink != null && calendarLink.isNotEmpty) {
        request.fields['calendar_link'] = calendarLink;
      }

      request.headers['Authorization'] = 'Bearer $token';

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'event_image',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(utf8.decode(response.bodyBytes))};
      } else {
        return {'success': false, 'error': jsonDecode(utf8.decode(response.bodyBytes))};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  // Delete an Event
  Future<bool> deleteEvent(int eventId) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$eventId/'), 
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204; 
    } catch (e) {
      return false;
    }
  }

  // Join an Event
  Future<Map<String, dynamic>> joinEvent(int eventId, {required bool asCrew}) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');

    final String endpoint = asCrew 
        ? '$_baseUrl$eventId/join-crew/' 
        : '$_baseUrl$eventId/join-participant/';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) { 
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'error': responseBody['error'] ?? 'An error occurred'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  // Get Potential Participants (For Meetings)
  Future<List<Map<String, dynamic>>> getPotentialParticipants() async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    // --- UPDATED: Use Production URL (Note: This points to 'users' app) ---
    final response = await http.get(
      Uri.parse('https://knowa.up.railway.app/api/users/admin/user-selection-list/'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  // Create Meeting
  Future<bool> createMeeting(Map<String, dynamic> meetingData) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    // --- UPDATED: Use Production URL ---
    final response = await http.post(
      Uri.parse('https://knowa.up.railway.app/api/events/meetings/create/'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(meetingData),
    );
    return response.statusCode == 201;
  }

  // Update Meeting
  Future<bool> updateMeeting(int id, Map<String, dynamic> meetingData) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    try {
      final response = await http.patch( 
        Uri.parse('${_baseUrl}meetings/$id/'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(meetingData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating meeting: $e");
      return false;
    }
  }

  // Delete Meeting
  Future<bool> deleteMeeting(int id) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    try {
      final response = await http.delete(
        Uri.parse('${_baseUrl}meetings/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 204; 
    } catch (e) {
      print("Error deleting meeting: $e");
      return false;
    }
  }
}