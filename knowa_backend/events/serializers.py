# events/serializers.py
from rest_framework import serializers
from .models import Event
from users.models import User # Import your custom User model

class EventSerializer(serializers.ModelSerializer):
    # This will show the username of the organizer, not just their ID number
    organizer_username = serializers.ReadOnlyField(source='organizer.username')

    # This allows us to assign the organizer on the backend automatically
    organizer = serializers.HiddenField(
        default=serializers.CurrentUserDefault()
    )

    class Meta:
        model = Event
        # These are the fields your Flutter app will send and receive
        fields = [
            'id', 
            'title', 
            'description', 
            'location', 
            'start_time', 
            'end_time', 
            'event_image',
            'organizer', # Will be set automatically
            'organizer_username', # For display
            'participants' # We'll use this later
        ]
        # Make 'participants' read-only for now
        read_only_fields = ['participants']