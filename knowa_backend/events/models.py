# events/models.py
from django.db import models
from django.conf import settings # We'll use this to link to our custom User

class Event(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=200)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()

    # This is for the event card's image
    event_image = models.ImageField(upload_to='event_images/', blank=True, null=True)

    # This links the event to the admin/staff who created it
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL, # If organizer is deleted, keep the event
        null=True,
        related_name="organized_events"
    )

    # This will store all the "Public Users" who registered
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="joined_events",
        blank=True # A new event can have zero participants
    )

    def __str__(self):
        return self.title