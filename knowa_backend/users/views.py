# users/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from .serializers import UserRegistrationSerializer, AdminUserSerializer, UserProfileSerializer, InterviewSerializer
from .models import User, UserProfile, Interview
from django.contrib.auth import authenticate # For checking passwords
from django.core.mail import send_mail
from django.conf import settings
from .serializers import MyTokenObtainPairSerializer # We'll use this to create the token
from django.utils import timezone
from django.db.models import Sum, Q
from events.models import Event
from donations.models import Donation, DonationStatus
from .models import Notification
from .serializers import NotificationSerializer
from .utils import send_notification
from events.models import Event, Meeting

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
    
    def get_serializer_context(self):
        # This passes the 'request' to AdminUserSerializer,
        # which passes it to UserProfileSerializer
        return {'request': self.request}

# 2. View to APPROVE a user
class ApproveForMembershipView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(
                pk=pk, 
                member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW]
            )
            user.member_status = User.MemberStatus.APPROVED_UNPAID # This flow is correct
            user.save()

            send_notification(
            user, 
            "Membership Application Approved", 
            "Congratulations! Your application has been approved. Please proceed to the dashboard to pay your membership fee.",
            "SUCCESS"
            )
            return Response({'status': 'User approved, awaiting payment.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not pending/interview'}, status=status.HTTP_404_NOT_FOUND)
        
class ApproveAsVolunteerView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(
                pk=pk, 
                member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW]
            )
            # This is the new flow: directly to Volunteer
            user.member_status = User.MemberStatus.VOLUNTEER 
            user.save()
            return Response({'status': 'User approved as Volunteer.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not pending/interview'}, status=status.HTTP_404_NOT_FOUND)

# 3. View to REJECT a user
class RejectUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            # Get the user
            user = User.objects.get(
                pk=pk, 
                member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW]
            )
            
            # 1. Update Status
            user.member_status = User.MemberStatus.REJECTED
            user.save()

            # 2. Save the Reason (in the profile)
            reason = request.data.get('reason', 'Application rejected by Admin')
            # Ensure profile exists before saving
            if hasattr(user, 'profile'):
                user.profile.rejection_reason = reason
                user.profile.save()

            return Response({'status': 'User rejected', 'reason': reason}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not pending'}, status=status.HTTP_404_NOT_FOUND)

# 4. View to set user status to INTERVIEW
class InterviewUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk)
            user.member_status = User.MemberStatus.INTERVIEW
            user.save()

            date_time = request.data.get('date_time')
            meeting_link = request.data.get('meeting_link', '')
            
            # --- NEW: Get the selected staff ID ---
            interviewer_id = request.data.get('interviewer_id') 
            interviewer = None
            if interviewer_id:
                try:
                    interviewer = User.objects.get(pk=interviewer_id)
                except User.DoesNotExist:
                    pass # Fallback to None (or scheduler)
            # --------------------------------------

            if date_time:
                Interview.objects.update_or_create(
                    applicant=user,
                    defaults={
                        'scheduler': request.user,   # The Admin who clicked
                        'interviewer': interviewer,  # The Staff chosen
                        'date_time': date_time,
                        'meeting_link': meeting_link,
                        'status': 'SCHEDULED'
                    }
                )
            
            return Response({'status': 'User set for interview'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
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

# This view allows a user to submit their application
class SubmitApplicationView(generics.UpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserProfileSerializer
    queryset = UserProfile.objects.all()

    def get_object(self):
        # Users can only update their *own* profile
        return self.request.user.profile

    def perform_update(self, serializer):
        # Save the profile data
        serializer.save()

        # --- THIS IS THE KEY ---
        # After saving, change the user's status to PENDING
        user = self.request.user
        user = self.request.user
        if user.member_status == User.MemberStatus.PUBLIC:
            user.member_status = User.MemberStatus.PENDING
            
            # --- Set the application date to NOW ---
            user.profile.application_date = timezone.now()
            user.profile.save()
            # --------------------------------------------
            
            user.save()
# --- ADD THESE NEW PAYMENT FLOW VIEWS ---

# 5. View for a user to upload their payment receipt
class UploadReceiptView(generics.UpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserProfileSerializer
    queryset = UserProfile.objects.all()

    def get_object(self):
        # Users can only update their own profile
        return self.request.user.profile

    def perform_update(self, serializer):
        # Save the payment_receipt file
        serializer.save()

        # This doesn't make them a member yet.
        # It just submits the receipt for admin review.


# 6. View for Admins to see users awaiting payment confirmation
class PendingPaymentListView(generics.ListAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = AdminUserSerializer # We can reuse this serializer

    def get_queryset(self):
        # Return all users who are "Approved (Unpaid)"
        # AND have uploaded a payment receipt
        return User.objects.filter(
            member_status=User.MemberStatus.APPROVED_UNPAID,
            profile__payment_receipt__isnull=False # Only show users who have uploaded a receipt
        )

# 7. View for Admins to confirm payment and make user a MEMBER
class ConfirmPaymentView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(
                pk=pk, 
                member_status=User.MemberStatus.APPROVED_UNPAID
            )
            user.member_status = User.MemberStatus.MEMBER # <-- FINAL STEP
            user.save()
            return Response({'status': 'Payment confirmed. User is now a member.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not awaiting payment.'}, status=status.HTTP_404_NOT_FOUND)
        
class RejectPaymentView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(
                pk=pk, 
                member_status=User.MemberStatus.APPROVED_UNPAID
            )
            # We change status to REJECTED so they are removed from the list
            user.member_status = User.MemberStatus.REJECTED 
            user.save()
            return Response({'status': 'Payment rejected. User application rejected.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found or not awaiting payment.'}, status=status.HTTP_404_NOT_FOUND)
        
# This view calculates all the stats for the Admin Dashboard
class AdminDashboardStatsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, format=None):
        # 1. Total Members
        total_members = User.objects.filter(
            Q(member_status=User.MemberStatus.MEMBER) | Q(is_staff=True)
        ).count()

        # 2. Pending Applications
        pending_applications = User.objects.filter(
            member_status=User.MemberStatus.PENDING
        ).count()

        # 3. Active Events
        active_events = Event.objects.filter(
            status=Event.EventStatus.PUBLISHED,
            end_time__gte=timezone.now() # "greater than or equal to now"
        ).count()

        # 4. Monthly Donations
        current_month = timezone.now().month
        current_year = timezone.now().year
        monthly_donations = Donation.objects.filter(
            status=DonationStatus.APPROVED,
            submitted_at__year=current_year,
            submitted_at__month=current_month
        ).aggregate(Sum('amount'))['amount__sum'] or 0.00

        # Create the data to send back
        data = {
            'total_members': total_members,
            'pending_applications': pending_applications,
            'active_events': active_events,
            'monthly_donations': monthly_donations
        }
        return Response(data, status=status.HTTP_200_OK)
    
# users/views.py

class MyScheduleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        schedule = []
        user = request.user

        # 1. Interviews (No changes)
        interviews = Interview.objects.filter(
            Q(applicant=user) | Q(scheduler=user) | Q(interviewer=user),
            status='SCHEDULED'
        )
        for i in interviews:
            title = "Interview"
            if user == i.applicant:
                interviewer_name = i.interviewer.first_name if i.interviewer else (i.scheduler.first_name if i.scheduler else 'Admin')
                title = f"Interview with {interviewer_name}"
            else:
                title = f"Interview: {i.applicant.first_name}"

            schedule.append({
                'id': i.id,
                'title': title,
                'date': i.date_time.date(),
                'time': i.date_time.strftime("%I:%M %p"),
                'type': 'INTERVIEW',
                'location': i.location,
                'meeting_link': i.meeting_link,
                'description': 'Interview session',
            })

        # --- 2. EVENTS (THE FIX IS HERE) ---
        if user.is_staff:
            # Admins see ALL events
            events = Event.objects.all()
        else:
            # Regular users see events if they are:
            # 1. A Participant
            # 2. In the Crew (THIS WAS MISSING)
            # 3. The Organizer
            events = Event.objects.filter(
                Q(participants=user) | Q(crew=user) | Q(organizer=user)
            ).distinct()

        for e in events:
            schedule.append({
                'id': e.id,
                'title': e.title,
                'date': e.start_time.date(),
                'time': e.start_time.strftime("%I:%M %p"),
                'type': 'EVENT',
                'location': e.location,
                'meeting_link': '', 
                'description': e.description,
            })
        # --------------------------------

        # 3. Meetings (No changes)
        meetings = Meeting.objects.filter(Q(participants=user) | Q(organizer=user)).distinct()
        for m in meetings:
            loc = m.location if not m.is_online else "Online"
            link = m.location if m.is_online else ""

            schedule.append({
                'id': m.id,
                'title': m.title,
                'date': m.start_time.date(),
                'time': m.start_time.strftime("%I:%M %p"),
                'type': 'MEETING',
                'location': loc,
                'meeting_link': link,
                'description': m.description,
            })

        return Response(schedule, status=status.HTTP_200_OK)

#VIEW: Get list of staff members
class StaffListView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        # Get users who are staff
        staff_members = User.objects.filter(is_staff=True)
        
        data = []
        for u in staff_members:
            # 1. PRIORITY: Use the First Name if it exists
            if u.first_name and u.first_name.strip():
                 display_name = u.first_name
            
            # 2. FALLBACK: Use username, but remove the email part (@gmail.com)
            # This turns "knowahead01@gmail.com" into "knowahead01"
            else:
                display_name = u.username.split('@')[0]

            data.append({'id': u.id, 'name': display_name})
            
        return Response(data, status=status.HTTP_200_OK)
    
class NotificationListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        # Show newest first
        return Notification.objects.filter(recipient=self.request.user).order_by('-created_at')

class MarkNotificationReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, recipient=request.user)
            notif.is_read = True
            notif.save()
            return Response({'status': 'Marked as read'}, status=status.HTTP_200_OK)
        except Notification.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        
class UserSelectionListView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        # 1. Fetch distinct groups
        admins = User.objects.filter(is_staff=True)
        members = User.objects.filter(member_status=User.MemberStatus.MEMBER)
        volunteers = User.objects.filter(member_status=User.MemberStatus.VOLUNTEER)

        def format_user(u, role):
            # Prioritize Full Name, fallback to username
            name = u.get_full_name().strip() or u.first_name.strip() or u.username
            return {'id': u.id, 'name': name, 'email': u.email, 'role': role}

        results = []
        # Add Admins
        for u in admins:
            results.append(format_user(u, 'ADMIN'))
        
        # Add Members (exclude if they are already added as admin)
        admin_ids = [a.id for a in admins]
        for u in members:
            if u.id not in admin_ids:
                results.append(format_user(u, 'MEMBER'))

        # Add Volunteers
        for u in volunteers:
             if u.id not in admin_ids: # Safety check
                results.append(format_user(u, 'VOLUNTEER'))

        return Response(results, status=status.HTTP_200_OK)