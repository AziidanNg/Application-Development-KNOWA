from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.shortcuts import get_object_or_404  # Needed for PinMessageView

from .models import ChatRoom, Message
from .serializers import (
    ChatRoomSerializer, 
    MessageSerializer, 
    ChatRoomDetailSerializer  # Added this import
)

# 1. List Chat Rooms (KEEPING YOUR CUSTOM LOGIC)
class ChatRoomListView(generics.ListAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Logic: Show rooms if user is participant OR part of the Event
        return ChatRoom.objects.filter(
            Q(participants=user) | 
            Q(event__organizer=user) |
            Q(event__crew=user) |
            Q(event__participants=user)
        ).distinct()

# 2. NEW: Get Single Chat Details (For Group Info Screen)
class ChatRoomDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    queryset = ChatRoom.objects.all()
    serializer_class = ChatRoomDetailSerializer

# 3. List Messages (Your existing logic)
class MessageListView(generics.ListCreateAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        room_id = self.kwargs['room_id']
        return Message.objects.filter(room_id=room_id).order_by('timestamp')

    def perform_create(self, serializer):
        room_id = self.kwargs['room_id']
        room = get_object_or_404(ChatRoom, pk=room_id) # Safer than .get()
        serializer.save(sender=self.request.user, room=room)

# 4. NEW: Pin Message View (For the "Long Press" feature)
class PinMessageView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        message = get_object_or_404(Message, pk=pk)
        
        # Security: Check if user is allowed to pin
        # (Checks if they are a participant or the event organizer)
        user = request.user
        has_permission = False
        
        if user in message.room.participants.all():
            has_permission = True
        elif message.room.event and (user == message.room.event.organizer or user in message.room.event.crew.all()):
            has_permission = True
            
        if not has_permission:
             return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

        # Toggle Pin
        message.is_pinned = not message.is_pinned
        message.save()
        
        return Response({
            'status': 'success', 
            'is_pinned': message.is_pinned
        })