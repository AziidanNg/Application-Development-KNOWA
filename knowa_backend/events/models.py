# events/models.py
# defines the Event model, tells Django what an event is and what information it has
from django.db import models
from django.conf import settings 

class Event(models.Model):
    # --- NEW STATUS CHOICES ---
    class EventStatus(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        PUBLISHED = 'PUBLISHED', 'Published'
        COMPLETED = 'COMPLETED', 'Completed'
        CANCELLED = 'CANCELLED', 'Cancelled'

    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=200, blank=True) # Blank=True for online events
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    event_image = models.ImageField(upload_to='event_images/', blank=True, null=True)
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL, 
        null=True,
        related_name="organized_events"
    )
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="joined_events",
        blank=True
    )

    # This is for "Members" (Crew)
    crew = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="joined_events_as_crew",
        blank=True
    )

    # --- NEW FIELDS FROM YOUR DESIGN ---
    status = models.CharField(
        max_length=10,
        choices=EventStatus.choices,
        default=EventStatus.DRAFT
    )

    capacity_participants = models.PositiveIntegerField(default=50)
    capacity_crew = models.PositiveIntegerField(default=10)

    calendar_link = models.URLField(max_length=500, blank=True, null=True) # For "Calendar Link"
    is_online = models.BooleanField(default=False) # For "Online" / "Offline"

    def __str__(self):
        return self.title