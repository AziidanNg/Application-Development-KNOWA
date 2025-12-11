from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from events.models import Event, Meeting
from users.utils import send_notification
from users.models import Notification

class Command(BaseCommand):
    help = 'Sends reminders for events and meetings starting in the next 24 hours'

    def handle(self, *args, **kwargs):
        now = timezone.now()
        upcoming_window = now + timedelta(hours=24) # Check next 24 hours

        self.stdout.write("Checking for upcoming events and meetings...")

        # --- 1. CHECK EVENTS ---
        events = Event.objects.filter(
            start_time__gt=now,
            start_time__lte=upcoming_window,
            status='PUBLISHED'
        )

        for event in events:
            time_until = event.start_time - now
            hours_until = int(time_until.total_seconds() / 3600)
            
            title = f"Reminder: Upcoming Event '{event.title}'"
            message = f"This is a reminder that '{event.title}' is starting in about {hours_until} hours ({event.start_time.strftime('%I:%M %p')}). We look forward to seeing you there!"

            # Combine all recipients (Participants + Crew + Organizer)
            # using set() to remove duplicates
            recipients = set(event.participants.all()) | set(event.crew.all())
            if event.organizer:
                recipients.add(event.organizer)

            for user in recipients:
                # Check if we already sent this specific reminder
                already_sent = Notification.objects.filter(
                    recipient=user,
                    title=title
                ).exists()

                if not already_sent:
                    send_notification(user, title, message, "INFO")
                    self.stdout.write(f"Sent event reminder to {user.username}")

        # --- 2. CHECK MEETINGS ---
        meetings = Meeting.objects.filter(
            start_time__gt=now,
            start_time__lte=upcoming_window
        )

        for meeting in meetings:
            time_until = meeting.start_time - now
            hours_until = int(time_until.total_seconds() / 3600)

            title = f"Reminder: Meeting '{meeting.title}'"
            message = f"You have a meeting '{meeting.title}' coming up in about {hours_until} hours."

            recipients = set(meeting.participants.all())
            if meeting.organizer:
                recipients.add(meeting.organizer)

            for user in recipients:
                already_sent = Notification.objects.filter(
                    recipient=user,
                    title=title
                ).exists()

                if not already_sent:
                    send_notification(user, title, message, "WARNING") # Warning icon grabs attention
                    self.stdout.write(f"Sent meeting reminder to {user.username}")

        self.stdout.write(self.style.SUCCESS('Reminder check complete.'))