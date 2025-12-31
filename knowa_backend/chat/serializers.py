from rest_framework import serializers
from .models import ChatRoom, Message
from django.contrib.auth import get_user_model

User = get_user_model()

# 1. Serializer for the User inside a chat (Handles Badges)
class ChatParticipantSerializer(serializers.ModelSerializer):
    role = serializers.SerializerMethodField()
    avatar = serializers.ImageField(source='profile.avatar', read_only=True) 

    class Meta:
        model = User
        fields = ['id', 'username', 'avatar', 'role']

    def get_role(self, user):
        chat_room = self.context.get('chat_room')
        if chat_room and chat_room.event:
            if chat_room.event.organizer == user:
                return "admin"
            # Adjust 'crew' if your Event model uses a different name for crew members
            if hasattr(chat_room.event, 'crew') and user in chat_room.event.crew.all():
                return "crew"
        return "member"

# 2. Serializer for Messages
class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    is_me = serializers.SerializerMethodField()  # <--- NEW FIELD

    class Meta:
        model = Message
        # Add 'is_me' to the fields list
        fields = ['id', 'sender', 'sender_name', 'content', 'timestamp', 'is_pinned', 'room', 'is_read', 'is_me']
        read_only_fields = ['sender', 'room', 'id', 'timestamp', 'is_pinned', 'is_read', 'is_me']

    def get_sender_name(self, obj):
        # Your existing name logic
        if obj.sender.first_name:
            return obj.sender.first_name
        username = obj.sender.username
        if '@' in username:
            return username.split('@')[0]
        return username

    # --- THE LOGIC TO CHECK IF "IT IS ME" ---
    def get_is_me(self, obj):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            return obj.sender == request.user
        return False

# 3. RESTORED: Standard Serializer for Listing Chat Rooms
class ChatRoomSerializer(serializers.ModelSerializer):
    # This uses the new __str__ method we wrote in models.py to show "(Event)"
    name = serializers.CharField(source='__str__', read_only=True) 
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'name', 'event']

# 4. New Serializer for Group Info Screen (Detailed)
class ChatRoomDetailSerializer(serializers.ModelSerializer):
    participants = serializers.SerializerMethodField()
    pinned_messages = serializers.SerializerMethodField()
    event_image = serializers.ImageField(source='event.image', read_only=True)
    name = serializers.CharField(source='__str__', read_only=True)

    class Meta:
        model = ChatRoom
        fields = ['id', 'name', 'participants', 'pinned_messages', 'event_image', 'description']

    def get_participants(self, obj):
        users = obj.participants.all()
        return ChatParticipantSerializer(users, many=True, context={'chat_room': obj}).data

    def get_pinned_messages(self, obj):
        pinned_msgs = obj.messages.filter(is_pinned=True).order_by('-timestamp')
        return MessageSerializer(pinned_msgs, many=True).data