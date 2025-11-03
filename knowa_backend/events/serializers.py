# events/serializers.py
from rest_framework import serializers
from .models import Event
from users.models import User

class EventSerializer(serializers.ModelSerializer):
    organizer_username = serializers.ReadOnlyField(source='organizer.username')
    organizer = serializers.HiddenField(
        default=serializers.CurrentUserDefault()
    )

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
            'organizer',
            'organizer_username',
            'participants',
            
            # --- THIS IS THE FIELD FOR "VISIBILITY" ---
            'status', 
            # ----------------------------------------
            
            'capacity',
            'calendar_link',
            'is_online',
        ]
        read_only_fields = ['participants']