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
  final String status;   // For "DRAFT", "PUBLISHED"
  final int capacityParticipants; 
  final int capacityCrew;         
  final int participantCount;     
  final int crewCount;            
  final String? calendarLink; // Make it nullable
  final bool isOnline;
  final bool isJoined;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
    required this.organizerUsername,
    required this.status,
    required this.capacityParticipants,
    required this.capacityCrew,
    required this.participantCount,
    required this.crewCount,
    this.calendarLink,
    required this.isOnline,
    required this.isJoined,
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
      capacityParticipants: json['capacity_participants'] ?? 0,
      capacityCrew: json['capacity_crew'] ?? 0,
      participantCount: json['participants_count'] ?? 0,
      crewCount: json['crew_count'] ?? 0,
      organizerUsername: json['organizer_username'] ?? 'Unknown',
      status: json['status'] ?? 'DRAFT',
      calendarLink: json['calendar_link'],
      isOnline: json['is_online'] ?? false,
      isJoined: json['is_joined'] ?? false,
    );
  }
}