# donations/views.py
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Donation
from .serializers import DonationCreateSerializer, DonationAdminSerializer
from django.db.models import Sum

# 1. API for a user to CREATE a new donation
class DonationCreateView(generics.CreateAPIView):
    """
    Allows any authenticated user to submit a donation (amount + receipt).
    The donation is set to 'PENDING' by default.
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DonationCreateSerializer

    def perform_create(self, serializer):
        # Automatically assign the logged-in user to the donation
        serializer.save(user=self.request.user)

# 2. API for an ADMIN to list PENDING donations
class PendingDonationListView(generics.ListAPIView):
    """
    Allows Admins to see a list of all donations with 'PENDING' status.
    """
    permission_classes = [permissions.IsAdminUser]
    serializer_class = DonationAdminSerializer

    def get_queryset(self):
        return Donation.objects.filter(status=Donation.DonationStatus.PENDING).order_by('-submitted_at')

    def get_serializer_context(self):
        # Pass the 'request' so the serializer can build full URLs
        return {'request': self.request}

# 3. API for an ADMIN to APPROVE a donation
class ApproveDonationView(APIView):
    """
    Allows Admins to change a donation's status from 'PENDING' to 'APPROVED'.
    """
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            donation = Donation.objects.get(pk=pk, status=Donation.DonationStatus.PENDING)
            donation.status = Donation.DonationStatus.APPROVED
            donation.save()
            return Response({'status': 'Donation approved'}, status=status.HTTP_200_OK)
        except Donation.DoesNotExist:
            return Response({'error': 'Pending donation not found.'}, status=status.HTTP_404_NOT_FOUND)

# 4. API for an ADMIN to REJECT a donation
class RejectDonationView(APIView):
    """
    Allows Admins to change a donation's status from 'PENDING' to 'REJECTED'.
    """
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            donation = Donation.objects.get(pk=pk, status=Donation.DonationStatus.PENDING)
            donation.status = Donation.DonationStatus.REJECTED
            donation.save()
            return Response({'status': 'Donation rejected'}, status=status.HTTP_200_OK)
        except Donation.DoesNotExist:
            return Response({'error': 'Pending donation not found.'}, status=status.HTTP_404_NOT_FOUND)

# 5. API to get the Donation Goal and Current Total
class DonationGoalView(APIView):
    """
    A public view to get the total approved donation amount and the goal.
    Matches the dashboard widgets.
    """
    permission_classes = [permissions.AllowAny] # Anyone can see this

    def get(self, request, format=None):
        # Calculate the sum of all APPROVED donations
        total_donated = Donation.objects.filter(
            status=Donation.DonationStatus.APPROVED
        ).aggregate(Sum('amount'))['amount__sum'] or 0.00 # 'or 0.00' handles if no donations exist

        goal = 10000.00 # We'll hardcode the RM10,000 goal for now

        return Response({
            'goal': goal,
            'current_total': total_donated
        }, status=status.HTTP_200_OK)