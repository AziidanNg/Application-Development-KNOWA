# donations/views.py
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Donation, DonationStatus # <--- DonationStatus is imported here
from .serializers import DonationCreateSerializer, DonationAdminSerializer
from django.db.models import Sum
from django.shortcuts import get_object_or_404
from rest_framework.parsers import MultiPartParser, FormParser

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
        # FIX: Use DonationStatus.PENDING directly (not Donation.DonationStatus.PENDING)
        return Donation.objects.filter(status=DonationStatus.PENDING).order_by('-submitted_at')

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
            # FIX: Use DonationStatus.PENDING directly
            donation = Donation.objects.get(pk=pk, status=DonationStatus.PENDING)
            
            # FIX: Use DonationStatus.APPROVED directly
            donation.status = DonationStatus.APPROVED
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
            # FIX: Use DonationStatus.PENDING directly
            donation = Donation.objects.get(pk=pk, status=DonationStatus.PENDING)
            
            # FIX: Use DonationStatus.REJECTED directly
            donation.status = DonationStatus.REJECTED
            donation.rejection_reason = request.data.get('reason', 'Issue with donation')
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
            # FIX: Use DonationStatus.APPROVED directly
            status=DonationStatus.APPROVED
        ).aggregate(Sum('amount'))['amount__sum'] or 0.00 

        goal = 10000.00 # We'll hardcode the RM10,000 goal for now

        return Response({
            'goal': goal,
            'current_total': total_donated
        }, status=status.HTTP_200_OK)
    
class UserLatestIssueView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # Find the most recent rejected donation for this user
        latest_issue = Donation.objects.filter(
            user=request.user, 
            status='REJECTED' # String check is fine here, or use DonationStatus.REJECTED
        ).order_by('-submitted_at').first()

        if latest_issue:
            return Response({
                'id': latest_issue.id,
                'reason': latest_issue.rejection_reason or "Issue detected by Admin",
                'date': latest_issue.submitted_at
            }, status=status.HTTP_200_OK)
        
        # If no issues found, return 204 No Content
        return Response(status=status.HTTP_204_NO_CONTENT)
    
class FixDonationView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser] # Required for file uploads

    def patch(self, request, pk):
        # Get the donation (ensure it belongs to the user)
        donation = get_object_or_404(Donation, pk=pk, user=request.user)
        
        # Check if a new file was sent
        if 'receipt' in request.data:
            # 1. Update the receipt
            donation.receipt = request.data['receipt']
            
            # 2. Reset status to PENDING (so Admin sees it again)
            # FIX: Use DonationStatus.PENDING directly
            donation.status = DonationStatus.PENDING
            
            # 3. Clear the rejection reason (issue resolved)
            donation.rejection_reason = None 
            
            donation.save()
            return Response({'status': 'fixed', 'message': 'Receipt updated successfully'}, status=status.HTTP_200_OK)
            
        return Response({'error': 'No receipt file provided'}, status=status.HTTP_400_BAD_REQUEST)