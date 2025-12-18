# users/views.py

# --- 1. STANDARD LIBRARIES & DJANGO IMPORTS ---
import google.generativeai as genai
from django.conf import settings
from django.contrib.auth import authenticate
from django.core.mail import send_mail
from django.utils import timezone
from django.db.models import Sum, Q

# --- 2. REST FRAMEWORK IMPORTS ---
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions

# --- 3. LOCAL APP IMPORTS (Models & Serializers) ---
from .models import User, UserProfile, Interview, Notification
from .utils import send_notification
from .serializers import (
    UserRegistrationSerializer, 
    AdminUserSerializer, 
    UserProfileSerializer, 
    InterviewSerializer,
    MyTokenObtainPairSerializer,
    NotificationSerializer
)

# --- 4. EXTERNAL APP IMPORTS (Events & Donations) ---
from events.models import Event, Meeting
from donations.models import Donation, DonationStatus


# ==========================================
# AUTHENTICATION & REGISTRATION VIEWS
# ==========================================

class RegistrationView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request, format=None):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'message': 'Registration successful. Account is pending approval.',
                'username': user.username,
                'status': user.member_status,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginRequestTACView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)

        if user is not None:
            tac = user.generate_tac()
            subject = 'Your KNOWA Login Code'
            message = f'Your temporary access code (TAC) is: {tac}\n\nThis code will expire in 5 minutes.'
            try:
                send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [user.email])
                return Response({'message': 'A 2FA code has been sent to your email.'}, status=status.HTTP_200_OK)
            except Exception:
                return Response({'error': 'Failed to send email.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class LoginVerifyTACView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        tac_code = request.data.get('tac_code')

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'error': 'Invalid user or TAC code.'}, status=status.HTTP_400_BAD_REQUEST)

        if user.is_tac_valid(tac_code):
            tokens = MyTokenObtainPairSerializer.get_token(user)
            return Response({
                'access': str(tokens.access_token),
                'refresh': str(tokens),
            }, status=status.HTTP_200_OK)
        return Response({'error': 'Invalid or expired TAC code.'}, status=status.HTTP_400_BAD_REQUEST)

class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        try:
            user = User.objects.get(email=email)
            tac = user.generate_tac()
            subject = 'Reset Your KNOWA Password'
            message = f'Your temporary access code (TAC) for password reset is: {tac}\n\nThis code will expire in 5 minutes.'
            send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [user.email])
        except User.DoesNotExist:
            pass # Security: Don't reveal if email exists
        return Response({'status': 'Password reset email sent.'}, status=status.HTTP_200_OK)

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

        if user.is_tac_valid(tac_code):
            user.set_password(password)
            user.save()
            return Response({'status': 'Password reset successful.'}, status=status.HTTP_200_OK)
        return Response({'error': 'Invalid or expired TAC code.'}, status=status.HTTP_400_BAD_REQUEST)


# ==========================================
# ADMIN & MANAGEMENT VIEWS
# ==========================================

class PendingUserListView(generics.ListAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = AdminUserSerializer
    
    def get_queryset(self):
        return User.objects.filter(member_status=User.MemberStatus.PENDING)
    
    def get_serializer_context(self):
        return {'request': self.request}

class ApproveForMembershipView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk, member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW])
            user.member_status = User.MemberStatus.APPROVED_UNPAID
            user.save()
            send_notification(user, "Membership Application Approved", "Congratulations! Your application has been approved. Please proceed to pay your membership fee.", "SUCCESS")
            return Response({'status': 'User approved, awaiting payment.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class ApproveAsVolunteerView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk, member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW])
            user.member_status = User.MemberStatus.VOLUNTEER 
            user.save()
            return Response({'status': 'User approved as Volunteer.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class RejectUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk, member_status__in=[User.MemberStatus.PENDING, User.MemberStatus.INTERVIEW])
            user.member_status = User.MemberStatus.REJECTED
            user.save()
            reason = request.data.get('reason', 'Application rejected by Admin')
            if hasattr(user, 'profile'):
                user.profile.rejection_reason = reason
                user.profile.save()
            return Response({'status': 'User rejected', 'reason': reason}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class InterviewUserView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk)
            user.member_status = User.MemberStatus.INTERVIEW
            user.save()

            date_time = request.data.get('date_time')
            meeting_link = request.data.get('meeting_link', '')
            interviewer_id = request.data.get('interviewer_id') 
            
            interviewer = None
            if interviewer_id:
                try:
                    interviewer = User.objects.get(pk=interviewer_id)
                except User.DoesNotExist:
                    pass

            if date_time:
                Interview.objects.update_or_create(
                    applicant=user,
                    defaults={
                        'scheduler': request.user,
                        'interviewer': interviewer,
                        'date_time': date_time,
                        'meeting_link': meeting_link,
                        'status': 'SCHEDULED'
                    }
                )
            return Response({'status': 'User set for interview'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class StaffListView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        staff_members = User.objects.filter(is_staff=True)
        data = []
        for u in staff_members:
            if u.first_name and u.first_name.strip():
                 display_name = u.first_name
            else:
                display_name = u.username.split('@')[0]
            data.append({'id': u.id, 'name': display_name})
        return Response(data, status=status.HTTP_200_OK)

class AdminDashboardStatsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, format=None):
        total_members = User.objects.filter(Q(member_status=User.MemberStatus.MEMBER) | Q(is_staff=True)).count()
        pending_applications = User.objects.filter(member_status=User.MemberStatus.PENDING).count()
        active_events = Event.objects.filter(status=Event.EventStatus.PUBLISHED, end_time__gte=timezone.now()).count()
        
        current_month = timezone.now().month
        current_year = timezone.now().year
        monthly_donations = Donation.objects.filter(
            status=DonationStatus.APPROVED,
            submitted_at__year=current_year,
            submitted_at__month=current_month
        ).aggregate(Sum('amount'))['amount__sum'] or 0.00

        data = {
            'total_members': total_members,
            'pending_applications': pending_applications,
            'active_events': active_events,
            'monthly_donations': monthly_donations
        }
        return Response(data, status=status.HTTP_200_OK)

# ==========================================
# USER PROFILE & PAYMENT VIEWS
# ==========================================

class SubmitApplicationView(generics.UpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserProfileSerializer
    queryset = UserProfile.objects.all()

    def get_object(self):
        return self.request.user.profile

    def perform_update(self, serializer):
        serializer.save()
        user = self.request.user
        if user.member_status == User.MemberStatus.PUBLIC:
            user.member_status = User.MemberStatus.PENDING
            user.profile.application_date = timezone.now()
            user.profile.save()
            user.save()

class UploadReceiptView(generics.UpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserProfileSerializer
    queryset = UserProfile.objects.all()

    def get_object(self):
        return self.request.user.profile

class PendingPaymentListView(generics.ListAPIView):
    permission_classes = [permissions.IsAdminUser]
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        return User.objects.filter(
            member_status=User.MemberStatus.APPROVED_UNPAID,
            profile__payment_receipt__isnull=False
        )

class ConfirmPaymentView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk, member_status=User.MemberStatus.APPROVED_UNPAID)
            user.member_status = User.MemberStatus.MEMBER
            user.save()
            return Response({'status': 'Payment confirmed.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

class RejectPaymentView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk, format=None):
        try:
            user = User.objects.get(pk=pk, member_status=User.MemberStatus.APPROVED_UNPAID)
            user.member_status = User.MemberStatus.REJECTED 
            user.save()
            return Response({'status': 'Payment rejected.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

# ==========================================
# SCHEDULE & UTILS VIEWS
# ==========================================

class MyScheduleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        schedule = []
        user = request.user

        # 1. Interviews
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

        # 2. Events
        if user.is_staff:
            events = Event.objects.all()
        else:
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

        # 3. Meetings
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

class NotificationListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
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
        admins = User.objects.filter(is_staff=True)
        members = User.objects.filter(member_status=User.MemberStatus.MEMBER)
        volunteers = User.objects.filter(member_status=User.MemberStatus.VOLUNTEER)

        def format_user(u, role):
            name = u.get_full_name().strip() or u.first_name.strip() or u.username
            return {'id': u.id, 'name': name, 'email': u.email, 'role': role}

        results = []
        for u in admins:
            results.append(format_user(u, 'ADMIN'))
        
        admin_ids = [a.id for a in admins]
        for u in members:
            if u.id not in admin_ids:
                results.append(format_user(u, 'MEMBER'))

        for u in volunteers:
             if u.id not in admin_ids:
                results.append(format_user(u, 'VOLUNTEER'))

        return Response(results, status=status.HTTP_200_OK)

# ==========================================
# AI CHATBOT VIEW
# ==========================================

class AIChatbotView(APIView):
    permission_classes = [permissions.AllowAny] 

    def post(self, request):
        user_message = request.data.get('message')
        
        if not user_message:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # DEBUG PRINT: Check if key is loaded
            print(f"DEBUG: Using API Key: {settings.GEMINI_API_KEY[:5]}...") 

            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel('gemini-2.5-flash')

            context = (
                "You are the helpful AI assistant for KNOWA. "
                "Keep answers short. "
                f"User asked: {user_message}"
            )

            # DEBUG PRINT: Sending request
            print("DEBUG: Sending request to Google...")
            
            response = model.generate_content(context)
            
            # DEBUG PRINT: Success
            print("DEBUG: Success!")
            
            return Response({'reply': response.text}, status=status.HTTP_200_OK)

        except Exception as e:
            # DEBUG PRINT: The actual error
            print(f"CRITICAL ERROR: {str(e)}") 
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)