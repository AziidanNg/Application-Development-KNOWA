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
        
        # 2. Base rule: EVERYONE (Guests & Users) sees questions meant for 'all'
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
        
        # --- GUEST LOGIC ---
        # We removed the 'else' block. 
        # If they are not logged in, they only keep the base filter (target_role='all').

        return FAQ.objects.filter(filters).distinct()