// lib/models/event.dart
import 'package:flutter/foundation.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String imageUrl;
  final String organizerUsername;
  
  // --- THE FIX: ADDING NEW FIELDS ---
  final String status;   // For "DRAFT", "PUBLISHED"
  final int capacity;
  final String? calendarLink; // Make it nullable
  final bool isOnline;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
    required this.organizerUsername,
    
    // --- ADD TO CONSTRUCTOR ---
    required this.status,
    required this.capacity,
    this.calendarLink,
    required this.isOnline,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      
      // Just use the full URL provided by the server
      imageUrl: json['event_image_url'] ?? '', 

      organizerUsername: json['organizer_username'] ?? 'Unknown',
      status: json['status'] ?? 'DRAFT',
      capacity: json['capacity'] ?? 0,
      calendarLink: json['calendar_link'],
      isOnline: json['is_online'] ?? false,
    );
  }
}