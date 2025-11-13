# users/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import User, UserProfile

@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    """
    Create a UserProfile when a new User is created.
    If an old user is saved (like an admin) and doesn't have one,
    create it for them.
    """
    if created:
        # 1. New user is created
        UserProfile.objects.create(user=instance)
    else:
        # 2. An existing user is saved
        # --- THIS IS THE FIX ---
        # Check if the user has a profile.
        if not hasattr(instance, 'profile'):
            # If not (like for your admin), create one.
            UserProfile.objects.create(user=instance)
        else:
            # If they do have a profile, save it (this is good practice).
            instance.profile.save()