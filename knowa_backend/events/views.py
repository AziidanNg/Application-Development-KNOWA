# events/views.py
# This file controls who can see, create, update, or delete events in the app
from rest_framework import generics, permissions
from .models import Event
from .serializers import EventSerializer
from django.utils import timezone

# This view will handle BOTH:
# 1. GET: Listing all events (for everyone)
# 2. POST: Creating a new event (for Admins only)
class EventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer

    def get_permissions(self):
        # This logic is still correct:
        # Only Admins can POST (create)
        if self.request.method == 'POST':
            return [permissions.IsAdminUser()]
        # Anyone can GET (view)
        return [permissions.AllowAny()]

    def perform_create(self, serializer):
        # This is also correct:
        serializer.save(organizer=self.request.user)

    # --- THIS IS THE NEW FIX ---
    # This function filters the list based on the user
    def get_queryset(self):
        user = self.request.user

        # Check if the user is logged in AND is an Admin (is_staff)
        if user.is_authenticated and user.is_staff:
            # If they are an Admin, send them ALL events
            return Event.objects.all().order_by('start_time')
        else:
            # If they are a Public User (or not logged in),
            # send them ONLY Published events that haven't happened yet.
            return Event.objects.filter(
                status=Event.EventStatus.PUBLISHED,
                start_time__gte=timezone.now() # gte = "greater than or equal to now"
            ).order_by('start_time')


# This view will handle GET, PUT, DELETE for a single event
class EventDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Event.objects.all()
    serializer_class = EventSerializer

    # --- THIS IS THE NEW PERMISSION LOGIC ---
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            # Only staff (Admins) can edit or delete an event
            return [permissions.IsAdminUser()]

        # Anyone (even public) can GET (view) the details
        return [permissions.AllowAny()]
    
    def get_serializer_context(self):
        # Pass the request context to the serializer
        return {'request': self.request}