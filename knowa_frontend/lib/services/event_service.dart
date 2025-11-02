// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowa_frontend/models/event.dart'; // Import the model we just made
import 'package:flutter/foundation.dart';

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

  // We will add getEventDetails(int id) here later
}