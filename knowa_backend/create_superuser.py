import os
import django

# 1. Setup Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "knowa_server.settings")
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# 2. Define Admin Credentials
USERNAME = 'admin'
EMAIL = 'admin@example.com'
PASSWORD = 'adminpassword123' 

# 3. Create the user
try:
    if not User.objects.filter(username=USERNAME).exists():
        print(f"Creating superuser: {USERNAME}...")
        User.objects.create_superuser(USERNAME, EMAIL, PASSWORD)
        print("Superuser created successfully!")
    else:
        print("Superuser already exists. Skipping.")
except Exception as e:
    print(f"Error creating superuser: {e}")