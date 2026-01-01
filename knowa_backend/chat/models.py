# chat/models.py
from django.db import models
from django.conf import settings
from events.models import Event

class ChatRoom(models.Model):
    # --- 1. NEW: Define Room Types ---
    class RoomType(models.TextChoices):
        EVENT = 'EVENT', 'Event Group'
        INTERVIEW = 'INTERVIEW', 'Interview Room'
        DIRECT = 'DIRECT', 'Direct Message'

    type = models.CharField(
        max_length=20, 
        choices=RoomType.choices, 
        default=RoomType.EVENT
    )
    # ---------------------------------

    description = models.TextField(blank=True, null=True)

    name = models.CharField(max_length=255, blank=True) # Explicit name for non-event chats

    event = models.ForeignKey( # Changed from OneToOne to ForeignKey for flexibility
        Event, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name="chat_rooms"
    )

    # --- 2. NEW: Link to Interview (String reference to avoid circular import) ---
    interview = models.OneToOneField(
        'users.Interview',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="chat_room"
    )

    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL, 
        related_name="chat_rooms",
        blank=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        if self.type == 'INTERVIEW':
             return self.name or f"Interview Chat {self.pk}"
        if self.event:
            return f"{self.event.title} (Event)"
        return f"Chat {self.pk}"

class Message(models.Model):
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # KEEP THIS: It will now mean "Read by EVERYONE"
    is_read = models.BooleanField(default=False) 
    is_pinned = models.BooleanField(default=False)

    # NEW FIELD: Tracks individual users who saw the message
    read_by = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='read_messages', blank=True)

    def __str__(self):
        return f"{self.sender.username}: {self.content[:20]}"