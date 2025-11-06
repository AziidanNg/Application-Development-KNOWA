# users/models.py
# define what user is, what info they have and what they can do
from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.utils.translation import gettext_lazy as _
import random
from django.utils import timezone
import datetime

class User(AbstractUser):
    
    # --- UPDATED CHOICES ---
    class MemberStatus(models.TextChoices):
        PUBLIC = 'PUBLIC', 'Public User'
        PENDING = 'PENDING', 'Pending Member'
        INTERVIEW = 'INTERVIEW', 'Interview'  # <-- for interview option
        MEMBER = 'MEMBER', 'NGO Member'
        REJECTED = 'REJECTED', 'Rejected'
    
    # --- UPDATED FIELD ---
    member_status = models.CharField(
        max_length=10,
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