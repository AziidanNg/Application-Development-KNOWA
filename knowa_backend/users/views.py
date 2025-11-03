# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from .serializers import UserRegistrationSerializer, AdminUserSerializer
from .models import User

#
# --- This is your RegistrationView ---
#
class RegistrationView(APIView):
    # This view will handle POST requests from the Flutter registration screen
    def post(self, request, format=None):
        serializer = UserRegistrationSerializer(data=request.data)
        
        if serializer.is_valid():
            # If valid, create the user
            user = serializer.save()
            return Response({
                'message': 'Registration successful. Account is pending approval.',
                'username': user.username,
                'status': user.member_status,
            }, status=status.HTTP_201_CREATED)
        
        # If invalid (e.g., passwords don't match, or username taken)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#
# --- These are your new Admin Views ---
#

# 1. View to get a list of all PENDING users
class PendingUserListView(generics.ListAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = AdminUserSerializer
    
    def get_queryset(self):
        # Return all users where member_status is 'PENDING'
        return User.objects.filter(member_status=User.MemberStatus.PENDING)

# 2. View to APPROVE a user
class ApproveUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            # You can approve a user who is PENDING or in INTERVIEW
            user = User.objects.get(
                pk=pk, 
                member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW]
            )
            user.member_status = User.MemberStatus.MEMBER # Change status to MEMBER
            user.save()
            return Response({'status': 'User approved'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not pending/interview'}, status=status.HTTP_404_NOT_FOUND)

# 3. View to REJECT a user
class RejectUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            # You can reject a user who is PENDING or in INTERVIEW
            user = User.objects.get(
                pk=pk, 
                member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW]
            )
            user.member_status = User.MemberStatus.REJECTED # Change status to REJECTED
            user.save()
            return Response({'status': 'User rejected'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not pending/interview'}, status=status.HTTP_404_NOT_FOUND)

# 4. View to set user status to INTERVIEW
class InterviewUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            # You can only move a user to Interview from Pending
            user = User.objects.get(pk=pk, member_status=User.MemberStatus.PENDING)
            user.member_status = User.MemberStatus.INTERVIEW # Change status to INTERVIEW
            user.save()
            return Response({'status': 'User set for interview'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'Pending user not found'}, status=status.HTTP_404_NOT_FOUND)