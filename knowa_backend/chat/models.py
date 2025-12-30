# chat/models.py
from django.db import models
from django.conf import settings
from events.models import Event

class ChatRoom(models.Model):
    # Link to an event (Group Chat). If null, it's a Direct Chat.
    event = models.OneToOneField(
        Event, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name="chat_room"
    )
    
    # Participants (for Direct Chats or extra members)
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL, 
        related_name="chat_rooms",
        blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        if self.event:
            return f"Group: {self.event.title}"
        return f"Direct Chat ({self.pk})"

class Message(models.Model):
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.sender.username}: {self.content[:20]}"