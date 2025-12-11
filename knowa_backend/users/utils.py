# users/utils.py
from django.core.mail import send_mail
from django.conf import settings
from .models import Notification, User
import threading

def send_notification(user, title, message, type='INFO'):
    # 1. Create In-App Notification
    Notification.objects.create(
        recipient=user,
        title=title,
        message=message,
        notification_type=type
    )

    # 2. Send Email (Wrap in try-except so it doesn't crash the app if internet is bad)
    try:
        # We use threading so the user doesn't have to wait for the email to send
        email_thread = threading.Thread(
            target=send_mail,
            args=(
                f"KNOWA Notification: {title}", # Subject
                message, # Body
                settings.DEFAULT_FROM_EMAIL, # From
                [user.email], # To
            ),
            kwargs={'fail_silently': True}
        )
        email_thread.start()
    except Exception as e:
        print(f"Failed to send email: {e}")

def notify_all_admins(title, message, type='WARNING'):
    admins = User.objects.filter(is_staff=True)
    for admin in admins:
        send_notification(admin, title, message, type)