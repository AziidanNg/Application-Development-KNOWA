# users/models.py
# define what user is, what info they have and what they can do
from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.utils.translation import gettext_lazy as _

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