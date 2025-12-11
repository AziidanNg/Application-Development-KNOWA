// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowa_frontend/models/event.dart'; // Import the model we just made
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; // For image uploads
import 'package:image_picker/image_picker.dart';

class EventService {
  // Use 10.0.2.2 for Android emulator
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
                          ? 'http://10.0.2.2:8000/api/events/'
                          : 'http://127.0.0.1:8000/api/events/';

  // Fetches the list of all events for the dashboard
  // Fetches the list of all events
  Future<List<Event>> getEvents() async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    // ---------------------

    try {
      // --- AND WE ADD THE TOKEN HEADER HERE ---
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Send the admin's token
        },
      );
      // ------------------------------------

      if (response.statusCode == 200) {
        // Decode the list of events
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));

        // Turn each JSON object into an Event object
        return jsonList.map((json) => Event.fromJson(json)).toList();
      } else {
        // Server error
        throw Exception('Failed to load events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Connection error
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  // Fetches the details for a single event
Future<Event> getEventDetails(int eventId) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl$eventId/'));

    if (response.statusCode == 200) {
      // Decode the single event object
      return Event.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Server error
      throw Exception('Failed to load event details.');
    }
  } catch (e) {
    // Connection error
    throw Exception('Connection failed: ${e.toString()}');
  }
}

// --- ADD THIS NEW FUNCTION TO CREATE AN EVENT ---
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

  // --- THIS IS THE FIX ---
  final _storage = const FlutterSecureStorage();
  final token = await _storage.read(key: 'access_token');
  // ---------------------

  try {
    var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['location'] = isOnline ? 'Online' : location;
    request.fields['start_time'] = startTime;
    request.fields['end_time'] = endTime;
    request.fields['capacity_participants'] = capacityParticipants.toString();
    request.fields['capacity_crew'] = capacityCrew.toString();
    request.fields['status'] = status;
    request.fields['is_online'] = isOnline.toString();
    if (calendarLink != null && calendarLink.isNotEmpty) {
      request.fields['calendar_link'] = calendarLink;
    }

    // --- THIS IS THE FIX ---
    // Add the authorization token to the request header
    request.headers['Authorization'] = 'Bearer $token';
    // ---------------------

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

  // ---NEW FUNCTION TO UPDATE AN EVENT ---
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

  // --- THIS IS THE FIX ---
  final _storage = const FlutterSecureStorage();
  final token = await _storage.read(key: 'access_token');
  // ---------------------

  try {
    var request = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl$eventId/'));

    // ... (all your request.fields are here) ...
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['location'] = isOnline ? 'Online' : location;
    request.fields['start_time'] = startTime;
    request.fields['end_time'] = endTime;
    request.fields['capacity_participants'] = capacityParticipants.toString();
    request.fields['capacity_crew'] = capacityCrew.toString();
    request.fields['status'] = status;
    request.fields['is_online'] = isOnline.toString();
    if (calendarLink != null && calendarLink.isNotEmpty) {
      request.fields['calendar_link'] = calendarLink;
    }

    // --- THIS IS THE FIX ---
    request.headers['Authorization'] = 'Bearer $token';
    // ---------------------

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

  // --- NEW FUNCTION TO DELETE AN EVENT ---
Future<bool> deleteEvent(int eventId) async {
  final _storage = const FlutterSecureStorage();
  final token = await _storage.read(key: 'access_token');

  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl$eventId/'), // Call DELETE on the event's URL
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204; // 204 means "No Content" (success)
  } catch (e) {
    return false;
  }
}

// --- ADD THIS NEW FUNCTION TO JOIN AN EVENT ---
Future<Map<String, dynamic>> joinEvent(int eventId, {required bool asCrew}) async {
  final _storage = const FlutterSecureStorage();
  final token = await _storage.read(key: 'access_token');

  // Determine which API endpoint to call
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

    if (response.statusCode == 200) { // 200 OK for success
      return {'success': true, 'data': responseBody};
    } else {
      // Send back the error message from the server (e.g., "Capacity is full")
      return {'success': false, 'error': responseBody['error'] ?? 'An error occurred'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
  }
}

Future<List<Map<String, dynamic>>> getPotentialParticipants() async {
  final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/users/admin/user-selection-list/'), // Adjust IP
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

  // 2. Create Meeting
  Future<bool> createMeeting(Map<String, dynamic> meetingData) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/events/meetings/create/'), // Adjust URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(meetingData),
    );
    return response.statusCode == 201;
  }

  // 3. Update Meeting
  Future<bool> updateMeeting(int id, Map<String, dynamic> meetingData) async {
    final _storage = const FlutterSecureStorage();
    final token = await _storage.read(key: 'access_token');
    
    try {
      final response = await http.patch( // Use PATCH for partial updates
        Uri.parse('${_baseUrl}meetings/$id/'), // This matches the new URL
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

  // 4. Delete Meeting
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
      return response.statusCode == 204; // 204 No Content = Success
    } catch (e) {
      print("Error deleting meeting: $e");
      return false;
    }
  }
}