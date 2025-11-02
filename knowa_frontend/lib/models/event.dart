// lib/models/event.dart
import 'package:flutter/foundation.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final String imageUrl;
  final String organizerUsername;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.imageUrl,
    required this.organizerUsername,
  });

  // This "factory constructor" builds an Event from the JSON data
  factory Event.fromJson(Map<String, dynamic> json) {

    // Helper to build the full image URL
    String getFullImageUrl(String? imageUrl) {
      if (imageUrl == null || imageUrl.isEmpty) {
        return ''; // Return an empty string if no image
      }
      // Use 10.0.2.2 for Android emulator
      String baseUrl = defaultTargetPlatform == TargetPlatform.android 
                       ? 'http://10.0.2.2:8000' 
                       : 'http://127.0.0.1:8000';
      return '$baseUrl$imageUrl';
    }

    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startTime: DateTime.parse(json['start_time']),
      imageUrl: getFullImageUrl(json['event_image']),
      organizerUsername: json['organizer_username'] ?? 'Unknown',
    );
  }
}