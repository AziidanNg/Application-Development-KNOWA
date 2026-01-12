# users/views.py

# --- 1. STANDARD LIBRARIES & DJANGO IMPORTS ---
from google import genai
from django.conf import settings
from django.contrib.auth import authenticate
from django.core.mail import send_mail
from django.utils import timezone
from django.db.models import Sum, Q

# --- 2. REST FRAMEWORK IMPORTS ---
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from rest_framework.permissions import IsAuthenticated

# --- 3. LOCAL APP IMPORTS (Models & Serializers) ---
from .models import User, UserProfile, Interview, Notification, UserFeedback
from .utils import send_notification, notify_all_admins
from .serializers import (
    UserRegistrationSerializer, 
    AdminUserSerializer, 
    UserProfileSerializer, 
    InterviewSerializer,
    MyTokenObtainPairSerializer,
    NotificationSerializer,
    UserSerializer,
    UserFeedbackSerializer
)

# --- 4. EXTERNAL APP IMPORTS (Events & Donations) ---
from events.models import Event, Meeting
from donations.models import Donation, DonationStatus
from chat.models import ChatRoom
from chatbot.models import FAQ


# ==========================================
# AUTHENTICATION & REGISTRATION VIEWS
# ==========================================

class RegistrationView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request, format=None):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            # --- 1. SET STATUS TO PUBLIC ---
            # This allows them to login, but they are not a "Member" yet.
            user.member_status = User.MemberStatus.PUBLIC 
            user.save()
            # -------------------------------
            
            # --- 2. SEND PROFESSIONAL WELCOME EMAIL ---
            try:
                # --- A. SETUP LINKS ---
                # REPLACE THIS URL with your actual logo link (from GitHub or Imgur)
                logo_url = "https://github.com/AziidanNg/Application-Development-KNOWA/blob/main/knowa_backend/users/logo.png?raw=true" 
                website_url = "https://knowa-app.online"
                
                # --- B. HTML DESIGN ---
                html_content = f"""
                <!DOCTYPE html>
                <html>
                <body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 40px;">
                    <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); text-align: center;">
                        
                        <img src="{logo_url}" alt="Knowa Logo" width="150" style="margin-bottom: 25px;">
                        
                        <h1 style="color: #1a202c; font-size: 24px; margin-bottom: 10px; font-weight: 700;">Welcome to KNOWA!</h1>
                        
                        <p style="color: #718096; font-size: 16px; margin-bottom: 30px; line-height: 1.6;">
                            Hi <strong>{user.username}</strong>,<br>
                            Thank you for joining our eco-community! You can now log in to the app to start your journey.
                            <br><br>
                            To become a verified Member, please go to your Profile and submit a <strong>Membership Application</strong>.
                        </p>
                        
                        <a href="{website_url}" style="background-color: #2f855a; color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">
                            Visit Website
                        </a>
                        
                        <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #edf2f7;">
                            <p style="color: #cbd5e0; font-size: 12px;">
                                &copy; 2026 Knowa App. All rights reserved.
                            </p>
                        </div>
                    </div>
                </body>
                </html>
                """

                # --- C. SEND MAIL ---
                send_mail(
                    subject='Welcome to KNOWA!',
                    # Plain text fallback for old devices
                    message=f'Hi {user.username},\n\nThank you for registering. You can now log in to the app.',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email],
                    html_message=html_content # <--- This enables the design
                )
            except Exception as e:
                print(f"Error sending welcome email: {e}")
            # -----------------------------

            return Response({
                'message': 'Registration successful. Please login.',
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
            
            # --- PROFESSIONAL HTML EMAIL DESIGN ---
            # 1. SETUP LINKS
            # REPLACE this URL if you have your own logo link
            logo_url = "https://github.com/AziidanNg/Application-Development-KNOWA/blob/main/knowa_backend/users/logo.png?raw=true" 
            website_url = "https://knowa-app.online"
            
            # 2. HTML TEMPLATE
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 40px;">
                <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); text-align: center;">
                    
                    <img src="{logo_url}" alt="Knowa Logo" width="150" style="margin-bottom: 25px;">
                    
                    <h1 style="color: #1a202c; font-size: 24px; margin-bottom: 10px; font-weight: 700;">Login Verification</h1>
                    <p style="color: #718096; font-size: 16px; margin-bottom: 30px; line-height: 1.5;">
                        Hello <strong>{user.username}</strong>,<br>
                        Please enter the following code to access your account.
                    </p>
                    
                    <div style="background-color: #f0fff4; color: #2f855a; border: 1px dashed #48bb78; padding: 20px; font-size: 32px; font-weight: bold; letter-spacing: 8px; border-radius: 8px; margin-bottom: 30px;">
                        {tac}
                    </div>
                    
                    <p style="color: #a0aec0; font-size: 14px; margin-bottom: 30px;">This code will expire in 5 minutes.</p>

                    <a href="{website_url}" style="background-color: #2f855a; color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">
                        Visit Website
                    </a>
                    
                    <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #edf2f7;">
                        <p style="color: #cbd5e0; font-size: 12px;">
                            &copy; 2026 Knowa App. All rights reserved.
                        </p>
                    </div>
                </div>
            </body>
            </html>
            """

            try:
                # 3. SEND MAIL (With HTML)
                send_mail(
                    subject='Your KNOWA Login Code',
                    message=f'Your temporary access code (TAC) is: {tac}', # Fallback for old phones
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[user.email],
                    html_message=html_content # <--- THIS ENABLES THE DESIGN
                )
                return Response({'message': 'A 2FA code has been sent to your email.'}, status=status.HTTP_200_OK)
            except Exception as e:
                # Print error to logs so you can debug if it fails
                print(f"Email Error: {str(e)}")
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
            
            # --- PROFESSIONAL HTML EMAIL DESIGN ---
            # 1. SETUP LINKS
            logo_url = "https://github.com/AziidanNg/Application-Development-KNOWA/blob/main/knowa_backend/users/logo.png?raw=true"
            website_url = "https://knowa-app.online"
            
            # 2. HTML TEMPLATE
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f6f8; margin: 0; padding: 40px;">
                <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); text-align: center;">
                    
                    <img src="{logo_url}" alt="Knowa Logo" width="150" style="margin-bottom: 25px;">
                    
                    <h1 style="color: #c0392b; font-size: 24px; margin-bottom: 10px; font-weight: 700;">Reset Your Password</h1>
                    <p style="color: #718096; font-size: 16px; margin-bottom: 30px; line-height: 1.5;">
                        Hello <strong>{user.username}</strong>,<br>
                        We received a request to reset your password. Enter the code below to proceed.
                    </p>
                    
                    <div style="background-color: #fff5f5; color: #c0392b; border: 1px dashed #fc8181; padding: 20px; font-size: 32px; font-weight: bold; letter-spacing: 8px; border-radius: 8px; margin-bottom: 30px;">
                        {tac}
                    </div>
                    
                    <p style="color: #a0aec0; font-size: 14px; margin-bottom: 10px;">This code expires in 5 minutes.</p>
                    <p style="color: #a0aec0; font-size: 13px; margin-bottom: 30px; font-style: italic;">If you did not request a password reset, you can safely ignore this email.</p>

                    <a href="{website_url}" style="background-color: #718096; color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 6px; font-weight: bold; font-size: 16px; display: inline-block;">
                        Visit Support
                    </a>
                    
                    <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #edf2f7;">
                        <p style="color: #cbd5e0; font-size: 12px;">
                            &copy; 2026 Knowa App. All rights reserved.
                        </p>
                    </div>
                </div>
            </body>
            </html>
            """

            # 3. SEND MAIL
            send_mail(
                subject='Reset Your KNOWA Password',
                message=f'Your password reset code is: {tac}', # Fallback text
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_content # <--- Enables Design
            )

        except User.DoesNotExist:
            pass # Security: Don't reveal if email exists or not
        except Exception as e:
            # Optional: Print error for debugging
            print(f"Password Reset Email Error: {e}")

        # Always return 200 OK to prevent email enumeration attacks
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
            
            # 1. Update Status
            user.member_status = User.MemberStatus.INTERVIEW
            user.save()

            # 2. Get Interview Details
            date_time = request.data.get('date_time')
            meeting_link = request.data.get('meeting_link', '')
            interviewer_id = request.data.get('interviewer_id') 
            
            interviewer = None
            if interviewer_id:
                try:
                    interviewer = User.objects.get(pk=interviewer_id)
                except User.DoesNotExist:
                    pass

            # 3. Create/Update Interview Record
            if date_time:
                interview_instance, created = Interview.objects.update_or_create(
                    applicant=user,
                    defaults={
                        'scheduler': request.user,
                        'interviewer': interviewer, # The staff member chosen
                        'date_time': date_time,
                        'meeting_link': meeting_link,
                        'status': 'SCHEDULED'
                    }
                )

                # ====================================================
                # AUTOMATIC CHAT ROOM CREATION
                # ====================================================
                # Check if room exists
                chat_room, room_created = ChatRoom.objects.get_or_create(
                    interview=interview_instance,
                    defaults={
                        'type': ChatRoom.RoomType.INTERVIEW,
                        'name': f"Interview: {user.first_name} - {interview_instance.status}"
                    }
                )

                if room_created:
                    # Add Participants: Applicant + Admin (Scheduler)
                    chat_room.participants.add(user)
                    chat_room.participants.add(request.user)
                    
                    # Add Assigned Interviewer (if different from Admin)
                    if interviewer and interviewer != request.user:
                        chat_room.participants.add(interviewer)

                    print(f"Created Interview Room ID: {chat_room.id}")
                # ====================================================

            return Response({
                'status': 'Interview scheduled and Chat Room created',
                'chat_room_id': chat_room.id if 'chat_room' in locals() else None
            }, status=status.HTTP_200_OK)

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
                'applicant_id': i.applicant.id,
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

class InterviewActionView(APIView):
    """
    Handles the result of an interview (Pass/Fail) AND saves the report.
    Updates BOTH the Interview status and the User status.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            # 1. Get the Applicant (User)
            applicant = User.objects.get(pk=pk)
            
            # 2. Find the interview for this applicant
            if not hasattr(applicant, 'interview'):
                 return Response({'error': "No interview found for this user."}, status=404)
            
            interview = applicant.interview

            # --- DEBUG PRINTS (To fix the Auth issue) ---
            print(f"DEBUG: Request User: {request.user.username} (ID: {request.user.id})")
            print(f"DEBUG: Is Superuser? {request.user.is_superuser}")
            print(f"DEBUG: Is Staff? {request.user.is_staff}")
            print(f"DEBUG: Interview Scheduler: {interview.scheduler}")
            print(f"DEBUG: Assigned Interviewer: {interview.interviewer}")
            # --------------------------------------------

            # 3. SECURITY CHECK: Who is clicking the button?
            is_authorized = (
                request.user.is_superuser or 
                request.user.is_staff or
                request.user == interview.scheduler or 
                request.user == interview.interviewer
            )

            if not is_authorized:
                return Response({'error': "You are not authorized to grade this interview."}, status=403)

            # 4. Get the action AND the report text
            action = request.data.get('action') 
            report_text = request.data.get('report', '') 

            # Save the report if provided
            if report_text:
                interview.report = report_text

            if action == 'pass':
                # --- LOGIC FOR PASSING ---
                applicant.member_status = User.MemberStatus.APPROVED_UNPAID
                applicant.save()

                interview.status = 'COMPLETED'
                interview.save() # Saves status + report

                send_notification(
                    applicant, 
                    "Interview Passed!", 
                    "Congratulations! You passed the interview. Please proceed to the dashboard to pay your membership fee.", 
                    "SUCCESS"
                )
                
                return Response({'status': 'User passed. Report saved.'}, status=status.HTTP_200_OK)

            elif action == 'fail':
                # --- LOGIC FOR FAILING ---
                applicant.member_status = User.MemberStatus.REJECTED
                applicant.save()

                interview.status = 'REJECTED'
                interview.save() # Saves status + report

                send_notification(
                    applicant, 
                    "Application Update", 
                    "Thank you for your interest. Unfortunately, your application was not successful at this time.", 
                    "ERROR"
                )

                return Response({'status': 'User rejected. Report saved.'}, status=status.HTTP_200_OK)

            else:
                return Response({'error': "Invalid action. Please send 'pass' or 'fail'."}, status=status.HTTP_400_BAD_REQUEST)

        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class AdminInterviewHistoryView(generics.ListAPIView):
    """
    Returns a list of all past interviews (Completed or Rejected)
    for the Admin to review reports.
    """
    permission_classes = [permissions.IsAdminUser]
    serializer_class = InterviewSerializer

    def get_queryset(self):
        # Filter for finished interviews, newest first
        return Interview.objects.filter(
            status__in=['COMPLETED', 'REJECTED']
        ).order_by('-date_time')

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

# Don't forget to import your model at the top
from .models import FAQ 

class AIChatbotView(APIView):
    permission_classes = [permissions.AllowAny] 

    def post(self, request):
        user_message = request.data.get('message')
        if not user_message:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # --- 1. FETCH EVENTS (Keep this, it's good) ---
            upcoming_events = Event.objects.filter(
                status='PUBLISHED',
                start_time__gte=timezone.now()
            ).order_by('start_time')[:3]

            events_context = "UPCOMING EVENTS:\n"
            if upcoming_events.exists():
                for event in upcoming_events:
                    date_str = event.start_time.strftime('%b %d, %I:%M %p')
                    events_context += f"- {event.title} on {date_str} ({event.location})\n"
            else:
                events_context += "No upcoming events found.\n"

            # --- 2. FETCH REAL DB FAQS (The Upgrade) ---
            # Instead of just hardcoding, let's grab the ones you imported!
            db_faqs = FAQ.objects.all()
            faq_context = "COMMON QUESTIONS & ANSWERS:\n"
            for faq in db_faqs:
                faq_context += f"Q: {faq.question}\nA: {faq.answer}\n"

            # --- 3. HARDCODED MANUAL (Keep as backup) ---
            app_manual = (
                "BASIC INSTRUCTIONS:\n"
                "1. REGISTRATION: Click 'Sign Up' on the Login screen.\n"
                "2. MEMBERSHIP: Status starts as 'Pending'. Pay fees to approve.\n"
                "3. DONATIONS: Use the blue 'Donate' button.\n"
                "4. PASSWORD: Use 'Forgot Password' for TAC code.\n"
            )

            # --- 4. CONFIGURE GEMINI ---
            api_key = getattr(settings, 'GEMINI_API_KEY', None)
            client = genai.Client(api_key=api_key)

            # Combine everything into the prompt
            full_prompt = (
                "You are the friendly AI support for KNOWA app. "
                "Answer using the context below.\n\n"
                f"{app_manual}\n"
                "---------------------\n"
                f"{faq_context}\n"  # <--- NOW THE AI KNOWS YOUR DB!
                "---------------------\n"
                f"{events_context}\n"
                "---------------------\n"
                f"USER QUESTION: {user_message}"
            )

            response = client.models.generate_content(
                model='gemini-2.0-flash', # Or 1.5-flash
                contents=full_prompt
            )

            return Response({'reply': response.text}, status=status.HTTP_200_OK)

        except Exception as e:
            print(f"Chatbot Error: {e}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class UserOptionsView(APIView):
    """
    Returns a list of users (Admins & Members) that can be added to a chat.
    """
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        # Fetch Staff and Approved Members, excluding the current user
        users = User.objects.filter(
            Q(is_staff=True) | Q(member_status=User.MemberStatus.MEMBER)
        ).exclude(id=request.user.id)

        data = []
        for u in users:
            role = "Admin" if u.is_staff else "Member"
            name = u.first_name if u.first_name else u.username
            data.append({'id': u.id, 'name': name, 'role': role, 'username': u.username})
            
        return Response(data, status=status.HTTP_200_OK)

class CurrentUserView(APIView):
    """
    Returns the full profile (with badges) for the currently logged-in user.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user, context={'request': request})
        return Response(serializer.data)

#==FEEDBACK==#
class SubmitFeedbackView(generics.CreateAPIView):
    queryset = UserFeedback.objects.all()
    serializer_class = UserFeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Automatically attach the user who sent it
        serializer.save(user=self.request.user)

class FeedbackListView(generics.ListAPIView):
    queryset = UserFeedback.objects.all().order_by('-created_at')
    serializer_class = UserFeedbackSerializer
    permission_classes = [permissions.IsAdminUser] # Only Admins allowed