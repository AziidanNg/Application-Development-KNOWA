# events/serializers.py
from rest_framework import serializers
from .models import Event
from users.models import User

class EventSerializer(serializers.ModelSerializer):
    organizer_username = serializers.ReadOnlyField(source='organizer.username')
    organizer = serializers.HiddenField(
        default=serializers.CurrentUserDefault()
    )

    # --- NEW: A field that builds the full URL ---
    event_image_url = serializers.SerializerMethodField()

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
            'participants',
            'status',
            'capacity',
            'calendar_link',
            'is_online',
        ]
        read_only_fields = ['participants']
        # We add this to hide the old 'event_image' path from the API
        extra_kwargs = {
            'event_image': {'write_only': True, 'required': False}
        }

    # --- NEW: The function that builds the full URL ---
    def get_event_image_url(self, obj):
        # Get the 'request' object from the context
        request = self.context.get('request')
        if obj.event_image and hasattr(obj.event_image, 'url'):
            # Build the full, absolute URL (e.g., http://.../media/...)
            return request.build_absolute_uri(obj.event_image.url)
        return None # Return null if no image