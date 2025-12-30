# chat/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from events.models import Event
from .models import ChatRoom

@receiver(post_save, sender=Event)
def create_event_chat_group(sender, instance, created, **kwargs):
    if created:
        # Standardize the name here
        group_name = f"{instance.title} (Event)"
        
        chat_group = ChatGroup.objects.create(
            name=group_name, 
            is_event_group=True, # Recommended flag
            related_event=instance # If you have a ForeignKey
        )