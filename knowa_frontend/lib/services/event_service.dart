// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowa_frontend/models/event.dart'; // Import the model we just made
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; // For image uploads

class EventService {
  // Use 10.0.2.2 for Android emulator
  final String _baseUrl = defaultTargetPlatform == TargetPlatform.android
                          ? 'http://10.0.2.2:8000/api/events/'
                          : 'http://127.0.0.1:8000/api/events/';

  // Fetches the list of all events for the dashboard
  Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        // Decode the list of events
        // We need to decode the UTF-8 body properly
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
  required int capacity,
  required String status,
  required bool isOnline,
  String? calendarLink,
  // We'll add the image file later
}) async {

  final _storage = const FlutterSecureStorage();
  final token = await _storage.read(key: 'access_token');

  try {
    // This is a "multi-part" request because it might include an image
    var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

    // Add all the text fields
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['location'] = isOnline ? 'Online' : location; // Set location
    request.fields['start_time'] = startTime;
    request.fields['end_time'] = endTime;
    request.fields['capacity'] = capacity.toString();
    request.fields['status'] = status; // e.g., "DRAFT" or "PUBLISHED"
    request.fields['is_online'] = isOnline.toString();
    if (calendarLink != null && calendarLink.isNotEmpty) {
      request.fields['calendar_link'] = calendarLink;
    }

    // Add the authorization token
    request.headers['Authorization'] = 'Bearer $token';

    // TODO: Add image file upload logic here
    // if (imageFile != null) {
    //   request.files.add(
    //     await http.MultipartFile.fromPath(
    //       'event_image',
    //       imageFile.path,
    //       contentType: MediaType('image', 'jpeg'), // Or 'png'
    //     ),
    //   );
    // }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) { // 201 means "Created"
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': jsonDecode(response.body)};
    }

  } catch (e) {
    return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
  }
}
}