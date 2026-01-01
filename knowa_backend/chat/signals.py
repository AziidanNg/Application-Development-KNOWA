from django.db.models.signals import post_save
from django.dispatch import receiver
from events.models import Event
from .models import ChatRoom 

@receiver(post_save, sender=Event)
def create_event_chat_group(sender, instance, created, **kwargs):
    if created:
        group_name = f"{instance.title} (Event)"
        
        chat_room = ChatRoom.objects.create(
            name=group_name,
            type='EVENT',
            event=instance 
        )
        
        # This ensures YOU (the creator) are added to the chat immediately
        if instance.organizer:
            chat_room.participants.add(instance.organizer)