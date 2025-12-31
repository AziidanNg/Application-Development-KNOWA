# chat/models.py
from django.db import models
from django.conf import settings
from events.models import Event

class ChatRoom(models.Model):
    event = models.OneToOneField(
        Event, 
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
    # Optional: Add a specific chat description if different from Event description
    description = models.TextField(blank=True, null=True) 

    def __str__(self):
        # 1. SOLVED: The Naming Convention Logic
        if self.event:
            return f"{self.event.title} (Event)"
        return f"Direct Chat ({self.pk})"

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