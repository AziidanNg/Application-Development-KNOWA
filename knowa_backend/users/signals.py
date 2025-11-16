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
        try:
            # Try to save the existing profile
            instance.profile.save()
        except UserProfile.DoesNotExist:
            # --- THIS IS THE FIX ---
            # If the profile doesn't exist (like for aziidanadmin),
            # create one for them on the fly.
            UserProfile.objects.create(user=instance)