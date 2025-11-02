# events/views.py
from rest_framework import generics, permissions
from .models import Event
from .serializers import EventSerializer

# This view will handle BOTH:
# 1. GET: Listing all events (for everyone)
# 2. POST: Creating a new event (for Admins only)
class EventListCreateView(generics.ListCreateAPIView):
    queryset = Event.objects.all().order_by('start_time') # Get all events
    serializer_class = EventSerializer

    # --- THIS IS THE NEW PERMISSION LOGIC ---
    def get_permissions(self):
        if self.request.method == 'POST':
            # Only staff (Admins) can POST (create) new events
            return [permissions.IsAdminUser()]

        # Anyone (even public) can GET (view) the list of events
        return [permissions.AllowAny()]

    # This automatically sets the 'organizer' to the logged-in admin user
    def perform_create(self, serializer):
        serializer.save(organizer=self.request.user)


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