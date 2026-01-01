import os
import django

# 1. Setup Django Environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'knowa_server.settings')
django.setup()

from chatbot.models import FAQ

def run():
    print("--- Deleting old FAQs... ---")
    FAQ.objects.all().delete()
    
    print("--- Loading Relevant Knowa FAQs... ---")

    faqs = [
        # --- GENERAL (ALL USERS) ---
        {
            "question": "What is Knowa?",
            "answer": "Knowa is a digital platform for managing community events and volunteering efficiently.",
            "target_role": "all",
            "order": 1
        },
        {
            "question": "How do I reset my password?",
            "answer": "Go to the Login screen and tap 'Forgot Password'. You will receive an email to set a new password.",
            "target_role": "all",
            "order": 2
        },
        {
            "question": "How do I edit my profile?",
            "answer": "Go to the Profile tab and tap the 'Edit' button to update your name and photo.",
            "target_role": "all",
            "order": 3
        },
        {
            "question": "Who is the AI Assistant?",
            "answer": "The Knowa Assistant is a chatbot designed to help you navigate the app and answer common questions.",
            "target_role": "all",
            "order": 4
        },

        # --- PARTICIPANTS ---
        {
            "question": "How do I join an event?",
            "answer": "Browse the 'Events' tab, click on an event you like, and tap the 'Join Event' button.",
            "target_role": "participant",
            "order": 5
        },
        {
            "question": "Where can I see my joined events?",
            "answer": "Go to the 'My Schedule' tab to see a list of all events you are currently registered for.",
            "target_role": "participant",
            "order": 6
        },

        # --- CHAT & COMMUNICATION ---
        {
            "question": "How do I chat with other members?",
            "answer": "Once you join an event, you will automatically be added to its Group Chat. You can find it in the 'Chat' tab.",
            "target_role": "participant",
            "order": 7
        },
        {
            "question": "What does a Blue Tick mean?",
            "answer": "In the chat, a Blue Tick means everyone in the group has read your message. Grey ticks mean it was delivered but not yet read by all.",
            "target_role": "participant",
            "order": 8
        },

        # --- ORGANIZERS (ADMINS) ---
        {
            "question": "How do I create a new event?",
            "answer": "Go to the Dashboard, tap the '+' icon, and fill in the event details to publish it.",
            "target_role": "organizer",
            "order": 9
        },
        {
            "question": "How do I pin a message?",
            "answer": "Long-press any message in the chat and select 'Pin Message'. This keeps important info at the top for everyone.",
            "target_role": "organizer",
            "order": 10
        },
    ]

    for item in faqs:
        FAQ.objects.create(**item)
        print(f"Created: {item['question']}")

    print("\n--- SUCCESS: 10 Current-State FAQs Loaded! ---")

if __name__ == '__main__':
    run()