from rest_framework import generics, permissions
from django.db.models import Q
from .models import FAQ
from .serializers import FAQSerializer

class FAQListView(generics.ListAPIView):
    # 1. Allow anyone (including guests) to read the FAQs
    permission_classes = [permissions.AllowAny]
    serializer_class = FAQSerializer

    def get_queryset(self):
        user = self.request.user
        
        # 2. Base rule: ALWAYS show questions meant for 'all'
        filters = Q(target_role='all')

        # 3. Check if user is actually logged in
        if user.is_authenticated:
            # --- LOGGED IN LOGIC ---
            if user.is_staff or user.is_superuser:
                # Staff see 'all' + 'organizer'
                filters |= Q(target_role='organizer')
            else:
                # Regular members see 'all' + 'participant'
                filters |= Q(target_role='participant')
        else:
            # --- GUEST LOGIC (Not Logged In) ---
            # Guests see 'all' + 'participant' (assuming "how to join" info is for participants)
            # You can remove the line below if you ONLY want them to see 'all'
            filters |= Q(target_role='participant')

        return FAQ.objects.filter(filters).distinct()