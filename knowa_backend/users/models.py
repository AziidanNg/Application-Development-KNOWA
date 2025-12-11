# users/models.py
# define what user is, what info they have and what they can do
from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.utils.translation import gettext_lazy as _
from django.conf import settings
import random
from django.utils import timezone
import datetime


class User(AbstractUser):
    
    # --- UPDATED CHOICES ---
    class MemberStatus(models.TextChoices):
        PUBLIC = 'PUBLIC', 'Public User'
        PENDING = 'PENDING', 'Pending Member'
        INTERVIEW = 'INTERVIEW', 'Interview'  # <-- for interview option
        APPROVED_UNPAID = 'APPROVED_UNPAID', 'Approved (Unpaid)'
        VOLUNTEER = 'VOLUNTEER', 'Volunteer'
        MEMBER = 'MEMBER', 'NGO Member'
        REJECTED = 'REJECTED', 'Rejected'
    
    # --- UPDATED FIELD ---
    member_status = models.CharField(
        max_length=20,
        choices=MemberStatus.choices,
        default=MemberStatus.PUBLIC  # <-- Default is now PUBLIC
    )

    phone = models.CharField(max_length=20, blank=True) # For Phone Number
    interests = models.CharField(max_length=255, blank=True) # Will store "Education,Arts"

    # --- 2FA FIELDS ---
    tac_code = models.CharField(max_length=6, blank=True, null=True)
    tac_expiry = models.DateTimeField(blank=True, null=True)

    # --- FIX from last time ---
    groups = models.ManyToManyField(
        Group,
        verbose_name=_('groups'),
        blank=True,
        help_text=_(
            'The groups this user belongs to. A user will get all permissions '
            'granted to each of their groups.'
        ),
        related_name="custom_user_groups", 
        related_query_name="user",
    )

    user_permissions = models.ManyToManyField(
        Permission,
        verbose_name=_('user permissions'),
        blank=True,
        help_text=_('Specific permissions for this user.'),
        related_name="custom_user_permissions",
        related_query_name="user",
    )

    # --- HELPER FUNCTIONS ---
    def generate_tac(self):
        """Generates a 6-digit TAC and sets expiry time for 5 minutes."""
        tac = str(random.randint(100000, 999999))
        self.tac_code = tac
        self.tac_expiry = timezone.now() + datetime.timedelta(minutes=5)
        self.save(update_fields=['tac_code', 'tac_expiry'])
        return tac

    def is_tac_valid(self, tac):
        """Checks if the provided TAC is correct and not expired."""
        if tac == self.tac_code and timezone.now() < self.tac_expiry:
            # TAC is valid, clear it to prevent reuse
            self.tac_code = None
            self.tac_expiry = None
            self.save(update_fields=['tac_code', 'tac_expiry'])
            return True
        return False
    
    # This model holds all the extra application data
class UserProfile(models.Model):
    # Link this profile to a specific user
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='profile'
    )

    # --- ADD THESE NEW CHOICES ---
    class ApplicationType(models.TextChoices):
        VOLUNTEER = 'VOLUNTEER', 'Project-Based Volunteer'
        MEMBERSHIP = 'MEMBERSHIP', 'Full Membership'

    # --- ADD THIS NEW FIELD ---
    # This stores the user's choice from the application form
    application_type = models.CharField(
        max_length=20,
        choices=ApplicationType.choices,
        blank=True, null=True # Allows it to be blank until they apply
    )

    application_date = models.DateTimeField(null=True, blank=True)

    # --- Background Fields (from image_1b2dc9.png) ---
    education = models.CharField(max_length=255, blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    reason_for_joining = models.TextField(blank=True, null=True)

    # --- New Fields You Requested ---
    ic_number = models.CharField(max_length=20, blank=True, null=True)

    # --- Attached Files (from image_1b26a2.png) ---
    # We need Pillow installed for this (which you already have)
    resume = models.FileField(upload_to='resumes/', blank=True, null=True)
    identification = models.FileField(upload_to='identifications/', blank=True, null=True)
    payment_receipt = models.FileField(upload_to='receipts/', blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.user.username}'s Profile"
    
# --- NEW SMART CALENDAR MODEL ---
class Interview(models.Model):
    # The Applicant
    applicant = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='interview')
    
    # The Admin who clicked the button (Scheduler)
    scheduler = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='scheduled_interviews')

    # --- NEW: The Staff Member conducting the interview ---
    interviewer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='assigned_interviews')
    # ----------------------------------------------------
    
    date_time = models.DateTimeField()
    location = models.CharField(max_length=255, default="Google Meet")
    meeting_link = models.URLField(blank=True, null=True)
    status = models.CharField(max_length=20, default='SCHEDULED')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Interview: {self.applicant.username} with {self.interviewer.username if self.interviewer else 'Admin'}"
    
class Notification(models.Model):
    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Optional: To help frontend show different icons
    notification_type = models.CharField(max_length=50, default='INFO') # INFO, SUCCESS, WARNING, ERROR

    def __str__(self):
        return f"Notification for {self.recipient.username}: {self.title}"