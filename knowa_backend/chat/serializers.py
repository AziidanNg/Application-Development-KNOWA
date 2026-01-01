from rest_framework import serializers
from .models import ChatRoom, Message
from django.contrib.auth import get_user_model
from users.serializers import UserSerializer

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
    # We use a method field to calculate the name dynamically
    name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    last_message_time = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'name', 'type', 'participants', 'last_message', 'last_message_time']

    def get_name(self, obj):
        # 1. If the room actually has a name, use it
        if obj.name and obj.name.strip():
            return obj.name
        
        # 2. If not, try to fetch the related Event title
        # (Assuming your ChatRoom model has a ForeignKey to 'event')
        if hasattr(obj, 'event') and obj.event:
            return obj.event.title
            
        return "Chat Room" # Fallback if everything is missing

    def get_last_message(self, obj):
        # Get the most recent message
        last_msg = obj.messages.order_by('-timestamp').first()
        if last_msg:
            return last_msg.content
        return "" 

    def get_last_message_time(self, obj):
        last_msg = obj.messages.order_by('-timestamp').first()
        if last_msg:
            return last_msg.timestamp
        return obj.created_at

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