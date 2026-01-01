from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.shortcuts import get_object_or_404  # Needed for PinMessageView
from users.models import User
from rest_framework import generics

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

class MarkMessagesReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        room = get_object_or_404(ChatRoom, pk=pk)
        user = request.user
        
        # 1. Add 'me' to the read list for all messages I haven't seen
        unread_messages = Message.objects.filter(room=room).exclude(sender=user).exclude(read_by=user)
        
        # 2. Calculate the "Target Audience" (Everyone in the chat)
        potential_readers = set(room.participants.all())
        if room.event:
            event = room.event
            potential_readers.add(event.organizer)
            potential_readers.update(event.crew.all())
            potential_readers.update(event.participants.all())
            
        # Convert to a Set of IDs
        target_audience_ids = {u.id for u in potential_readers}

        for msg in unread_messages:
            msg.read_by.add(user)
            
            # --- UPDATED LOGIC ---
            
            # 1. Who has read it?
            readers_ids = set(msg.read_by.values_list('id', flat=True))
            
            # 2. Define who MUST read it:
            #    (Target Audience MINUS The Sender)
            #    We don't care if the sender read it, they wrote it.
            must_read_ids = target_audience_ids.copy()
            if msg.sender_id in must_read_ids:
                must_read_ids.remove(msg.sender_id)
            
            # 3. Are there any "Must Read" people who haven't read it yet?
            remaining_unread = must_read_ids - readers_ids
            
            # 4. If NO ONE is left, turn Blue!
            if not remaining_unread:
                msg.is_read = True
                msg.save()

        return Response({'status': 'success', 'updated': unread_messages.count()})

class MessageInfoView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        message = get_object_or_404(Message, pk=pk)
        
        if message.sender != request.user:
            return Response({"error": "Only sender can view message info"}, status=status.HTTP_403_FORBIDDEN)

        # HELPER: Get Smart Name (First Name -> Username -> Email-free)
        def get_smart_name(user):
            if user.first_name:
                return user.first_name
            if '@' in user.username:
                return user.username.split('@')[0]
            return user.username

        # HELPER: Get Avatar Safely
        def get_avatar_url(user):
            if hasattr(user, 'profile'):
                if hasattr(user.profile, 'avatar') and user.profile.avatar:
                    return user.profile.avatar.url
                # Add other field checks if needed (e.g. image, photo)
            return None

        # 1. Who has read it?
        read_users = message.read_by.all()
        read_data = [{
            'username': get_smart_name(u), # Use smart name
            'avatar': get_avatar_url(u)
        } for u in read_users]

        # 2. Who is in the chat?
        potential_readers = set(message.room.participants.all())
        if message.room.event:
            event = message.room.event
            potential_readers.add(event.organizer)
            potential_readers.update(event.crew.all())
            potential_readers.update(event.participants.all())

        # 3. Who hasn't read it?
        unread_data = []
        for u in potential_readers:
            # Exclude Sender (Me) and Readers
            if u.id != request.user.id and u not in read_users:
                unread_data.append({
                    'username': get_smart_name(u), # Use smart name
                    'avatar': get_avatar_url(u)
                })

        return Response({
            'message': message.content,
            'timestamp': message.timestamp,
            'read_by': read_data,
            'delivered_to': unread_data
        })

class CreateChatRoomView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        participant_ids = request.data.get('participants', [])
        name = request.data.get('name', 'New Chat')
        # Default type is 'GENERAL' unless specified (e.g., CREW)
        room_type = request.data.get('type', 'GENERAL') 

        if not participant_ids:
             return Response({'error': 'Select at least one participant.'}, status=status.HTTP_400_BAD_REQUEST)

        # Create Room
        chat = ChatRoom.objects.create(name=name, type=room_type)
        
        # Add Creator (Admin)
        chat.participants.add(request.user)
        
        # Add Selected Users
        for uid in participant_ids:
            try:
                user = User.objects.get(pk=uid)
                chat.participants.add(user)
            except User.DoesNotExist:
                continue
        
        return Response({'id': chat.id, 'message': 'Chat created'}, status=status.HTTP_201_CREATED)

class DeleteChatRoomView(generics.DestroyAPIView):
    """
    Allows Admin to delete a chat room permanently.
    """
    permission_classes = [permissions.IsAdminUser]
    queryset = ChatRoom.objects.all()
    serializer_class = ChatRoomSerializer