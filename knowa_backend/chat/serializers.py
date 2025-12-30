# chat/serializers.py
from rest_framework import serializers
from .models import ChatRoom, Message

class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.ReadOnlyField(source='sender.first_name')
    
    class Meta:
        model = Message
        fields = ['id', 'sender_name', 'content', 'timestamp', 'is_read']

class ChatRoomSerializer(serializers.ModelSerializer):
    room_name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'room_name', 'event', 'last_message']

    def get_room_name(self, obj):
        if obj.event:
            return obj.event.title
        return "Direct Message"

    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-timestamp').first()
        if last_msg:
            return f"{last_msg.sender.first_name}: {last_msg.content[:30]}"
        return "No messages yet"