# events/views.py
# This file controls who can see, create, update, or delete events in the app
from rest_framework import generics, permissions
from rest_framework.views import APIView      
from rest_framework.response import Response  
from rest_framework import status             
from .models import Event
from .serializers import EventSerializer
from django.utils import timezone
from users.models import User
from .models import Meeting          
from .serializers import MeetingSerializer

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
    
# 3. View for a PUBLIC user to join as a PARTICIPANT
class JoinEventAsParticipantView(APIView):
    permission_classes = [permissions.IsAuthenticated] # User must be logged in

    def post(self, request, pk, format=None):
        try:
            event = Event.objects.get(pk=pk, status=Event.EventStatus.PUBLISHED)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found or not published'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user

        # Check if they are just a Public User
        if user.member_status != User.MemberStatus.PUBLIC:
            return Response({'error': 'Members must join as crew.'}, status=status.HTTP_403_FORBIDDEN)

        # Check if event is full
        if event.participants.count() >= event.capacity_participants:
            return Response({'error': 'Participant capacity is full.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if already registered
        if event.participants.filter(pk=user.pk).exists():
            return Response({'error': 'Already registered as a participant.'}, status=status.HTTP_400_BAD_REQUEST)

        # Add the user to the event
        event.participants.add(user)
        return Response({'status': 'Successfully registered as participant.'}, status=status.HTTP_200_OK)


# --- ADD THIS NEW VIEW ---
# 4. View for a MEMBER to join as CREW
class JoinEventAsCrewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk, format=None):
        try:
            event = Event.objects.get(pk=pk, status=Event.EventStatus.PUBLISHED)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found or not published'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user

        # Check if they are an approved Member or Staff
        if user.member_status != User.MemberStatus.MEMBER and not user.is_staff:
            return Response({'error': 'Only approved members can join as crew.'}, status=status.HTTP_403_FORBIDDEN)

        # Check if event is full
        if event.crew.count() >= event.capacity_crew:
            return Response({'error': 'Crew capacity is full.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if already registered
        if event.crew.filter(pk=user.pk).exists():
            return Response({'error': 'Already registered as crew.'}, status=status.HTTP_400_BAD_REQUEST)

        # Add the user to the event's crew
        event.crew.add(user)
        return Response({'status': 'Successfully registered as crew.'}, status=status.HTTP_200_OK)
    
class MeetingCreateView(generics.CreateAPIView):
    """
    Allows Admins to create a new meeting with selected participants.
    """
    queryset = Meeting.objects.all()
    serializer_class = MeetingSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admins can create meetings

    def perform_create(self, serializer):
        # Automatically set the 'organizer' to the admin who is currently logged in
        serializer.save(organizer=self.request.user)

class MeetingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Handles GET, PUT, PATCH, DELETE for a specific meeting.
    """
    queryset = Meeting.objects.all()
    serializer_class = MeetingSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admins can edit/delete