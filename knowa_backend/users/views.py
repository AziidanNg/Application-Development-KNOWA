# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from .serializers import UserRegistrationSerializer, AdminUserSerializer
from .models import User
from django.contrib.auth import authenticate # For checking passwords
from django.core.mail import send_mail
from django.conf import settings
from .serializers import MyTokenObtainPairSerializer # We'll use this to create the token

#
# --- This is your RegistrationView ---
#
class RegistrationView(APIView):
    # This view will handle POST requests from the Flutter registration screen
    # This line overrides the site default and allows ANYONE to register
    permission_classes = [permissions.AllowAny]
    
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
        
# 1. This view handles the INITIAL login (username + password)
# It sends the 2FA code via email.
class LoginRequestTACView(APIView):
    permission_classes = [permissions.AllowAny] # Anyone can try to log in

    def post(self, request, *args, **kwargs):
        username = request.data.get('username') # This can be the email
        password = request.data.get('password')

        user = authenticate(username=username, password=password)

        if user is not None:
            # Password is correct. Generate a TAC.
            tac = user.generate_tac()

            # Send the email
            subject = 'Your KNOWA Login Code'
            message = f'Your temporary access code (TAC) is: {tac}\n\nThis code will expire in 5 minutes.'

            try:
                send_mail(
                    subject, 
                    message, 
                    settings.DEFAULT_FROM_EMAIL, 
                    [user.email]
                )
                return Response({'message': 'A 2FA code has been sent to your email.'}, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'error': 'Failed to send email.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # Username or password was incorrect
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)


# 2. This view handles the FINAL login (username + TAC)
# It sends the real login tokens.
class LoginVerifyTACView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        tac_code = request.data.get('tac_code')

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Invalid user or TAC code.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if the TAC is valid (this also clears it)
        if user.is_tac_valid(tac_code):
            # TAC is correct. Manually create the login tokens.
            tokens = MyTokenObtainPairSerializer.get_token(user)

            return Response({
                'access': str(tokens.access_token),
                'refresh': str(tokens),
            }, status=status.HTTP_200_OK)

        # TAC was wrong or expired
        return Response({'error': 'Invalid or expired TAC code.'}, status=status.HTTP_400_BAD_REQUEST)
    
# --- NEW PASSWORD RESET VIEWS ---

# 1. View for REQUESTING a password reset
# This will find the user by email and send them a TAC code
class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny] # Anyone can request a reset

    def post(self, request):
        email = request.data.get('email')
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Don't tell the user the email failed, just say OK
            return Response({'status': 'Password reset email sent (if user exists).'}, status=status.HTTP_200_OK)

        # Generate a 6-digit TAC
        tac = user.generate_tac()

        # --- THIS IS THE EMAIL ---
        # It will print to your Django terminal
        subject = 'Reset Your KNOWA Password'
        message = f'Your temporary access code (TAC) for password reset is: {tac}\n\nThis code will expire in 5 minutes.'

        send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [user.email])

        return Response({'status': 'Password reset email sent.'}, status=status.HTTP_200_OK)


# 2. View for CONFIRMING the new password
class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        tac_code = request.data.get('tac_code')
        password = request.data.get('password')

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'Invalid user or TAC code.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if the TAC is valid (this also clears it)
        if user.is_tac_valid(tac_code):
            # TAC is correct, set the new password
            user.set_password(password)
            user.save()
            return Response({'status': 'Password reset successful.'}, status=status.HTTP_200_OK)
        else:
            # Token is invalid or expired
            return Response({'error': 'Invalid or expired TAC code.'}, status=status.HTTP_400_BAD_REQUEST)
