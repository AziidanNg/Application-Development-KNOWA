# events/serializers.py
# This file defines how event data is converted to and from JSON
# This file controls what event info is sent to users and how new events are created
from rest_framework import serializers
from .models import Event, Meeting
from users.models import User

class EventSerializer(serializers.ModelSerializer):
    organizer_username = serializers.ReadOnlyField(source='organizer.username')
    organizer = serializers.HiddenField(
        default=serializers.CurrentUserDefault()
    )

    # --- A field that builds the full URL ---
    event_image_url = serializers.SerializerMethodField()

    participants_count = serializers.SerializerMethodField()
    crew_count = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = [
            'id', 
            'title', 
            'description', 
            'location', 
            'start_time', 
            'end_time', 
            'event_image',
            'event_image_url', # <-- We will use this new field

            'organizer',
            'organizer_username',
            'status',
            'capacity_participants',
            'capacity_crew',
            'participants_count',
            'crew_count',
            'calendar_link',
            'is_online',
        ]
        # We don't need to send the whole 'participants' list for this view
        read_only_fields = [
            'organizer_username', 
            'event_image_url', 
            'participants_count', 
            'crew_count'
        ]
        extra_kwargs = {'event_image': {'write_only': True}}

    # --- The function that builds the full URL ---
    def get_event_image_url(self, obj):
        # Get the 'request' object from the context
        request = self.context.get('request')
        if obj.event_image and hasattr(obj.event_image, 'url'):
            # Build the full, absolute URL (e.g., http://.../media/...)
            return request.build_absolute_uri(obj.event_image.url)
        return None # Return null if no image
    
    # --- The function that counts participants ---
    def get_participants_count(self, obj):
        # This counts how many users are in the 'participants' list
        return obj.participants.count()
    
    # --- The function that counts crew ---
    def get_crew_count(self, obj):
        # This counts how many users are in the 'crew' list
        return obj.crew.count()
    
class MeetingSerializer(serializers.ModelSerializer):
    participant_count = serializers.SerializerMethodField()

    class Meta:
        model = Meeting
        fields = [
            'id', 'title', 'description', 'start_time', 'end_time', 
            'is_online', 'location', 'participant_count', 'participants'
        ]
        extra_kwargs = {'participants': {'write_only': True}}

    def get_participant_count(self, obj):
        return obj.participants.count()